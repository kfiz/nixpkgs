{
  lib,
  cmake,
  fixDarwinDylibNames,
  llvm_libtool,
  meson,
  ninja,
  stdenv,
  swift,
  swiftpmHook,
  build-system ? "swiftpm",
}:

let
  buildSystemDeps = {
    cmake = [
      cmake
      ninja
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # Many packages don’t correctly set the install name of the dylibs they produce.
      fixDarwinDylibNames
      # libtool (not the GNU one) is often required to build libraries.
      llvm_libtool
    ];
    meson = [
      meson
      ninja
    ];
    swiftpm = [ swiftpmHook ];
  };
  extraNativeBuildInputs =
    if build-system == null then
      [ ]
    else
      [ swift ] ++ buildSystemDeps.${build-system}
        or (throw "unsupported build system ${build-system}; please set `build-system` to `null` and specify `nativeBuildInputs` manually.");
in
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;
  extendDrvArgs =
    finalAttrs: args:
    let
      hasDev = lib.elem "dev" (args.outputs or [ ]);
      hasInclude = lib.elem "include" (args.outputs or [ ]);
    in
    # CMake parses `-print-target-info` to get the deployment target for Swift (ignoring `MACOSX_DEPLOYMENT_TARGET`),
    # which unfortunately defaults to the running OS version. Set a sensible default instead.
    # This is done in `preConfigure` to ensure that `darwinMinVersionHook` works.
    lib.optionalAttrs (build-system == "cmake" && stdenv.hostPlatform.isDarwin) {
      preConfigure = (args.preConfigure or "") + ''
        appendToVar cmakeFlags -DCMAKE_Swift_COMPILER_TARGET=${stdenv.hostPlatform.darwinArch}-apple-macosx$MACOSX_DEPLOYMENT_TARGET
        appendToVar cmakeFlags -DCMAKE_Swift_FLAGS=-module-cache-path\ "$NIX_BUILD_TOP/module-cache"
      '';
    }
    // lib.optionalAttrs hasInclude ({
      moveToDev = false;
      outputInclude = "include";
      preFixup = (args.preFixup or "") + ''
        # Make the "include" propagate other outputs needed for development
        # since `dev` is not a normal output for Swift packages.
        _multioutPropagateDev() {
            if [ "$(getAllOutputNames)" = "out" ]; then return; fi;

            local outputFirst
            for outputFirst in $(getAllOutputNames); do
                break
            done
            local propagaterOutput="$outputInclude"
            if [ -z "$propagaterOutput" ]; then
                propagaterOutput="$outputFirst"
            fi

            # Default value: propagate binaries and libraries
            local po_dirty="$outputBin $outputInclude $outputLib"
            set +o pipefail
            propagatedBuildOutputs=`echo "$po_dirty" \
                | tr -s ' ' '\n' | grep -v -F "$propagaterOutput" \
                | sort -u | tr '\n' ' ' `
            set -o pipefail

            mkdir -p "''${!propagaterOutput}"/nix-support
            for output in $propagatedBuildOutputs; do
                echo -n " ''${!output}" >> "''${!propagaterOutput}"/nix-support/propagated-build-inputs
            done
        }
      '';
    })
    // {
      postPatch = (args.postPatch or "") + ''
        # Install modules to $include, which needs to be separate from $dev to accommodate the source passthru.
        # Unfortunately, can’t use `--replace-fail` because packages don’t consistently use one version.
        if [ -e cmake/modules/SwiftSupport.cmake ]; then
            substituteInPlace cmake/modules/SwiftSupport.cmake \
              --replace-quiet 'ARCHIVE DESTINATION lib/''${swift}/''${swift_os}' 'ARCHIVE DESTINATION ''${CMAKE_INSTALL_LIBDIR}' \
              --replace-quiet 'LIBRARY DESTINATION lib/''${swift}/''${swift_os}' 'LIBRARY DESTINATION ''${CMAKE_INSTALL_LIBDIR}' \
              --replace-quiet 'RUNTIME DESTINATION bin' 'RUNTIME DESTINATION ''${CMAKE_INSTALL_BINDIR}' \
              --replace-quiet '    DESTINATION lib' "DESTINATION ''${!outputInclude}/lib" \
              --replace-quiet '    DESTINATION ''${CMAKE_INSTALL_LIBDIR}' "DESTINATION ''${!outputInclude}/lib"
        fi
      '';

      nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ extraNativeBuildInputs;

      strictDeps = true;
      __structuredAttrs = true;

      passthru =
        # Most Swift packages cannot (yet) provide pre-built artifacts that can be used in a build.
        # This hook makes the package’s patched source available to SwiftPM to use in dependent packages’ builds.
        lib.optionalAttrs (!hasDev) {
          dev = finalAttrs.finalPackage.overrideAttrs {
            outputs = [ "out" ];

            nativeBuildInputs = [ ];
            buildInputs = [ ];

            propagatedBuildInputs =
              lib.filter (x: (lib.getDev x).isSwiftPackage or false) (finalAttrs.buildInputs or [ ])
              ++ (finalAttrs.propagatedBuildInputs or [ ]);

            dontConfigure = true;
            dontInstall = true;

            buildPhase =
              let
                # Function names can have any character except for `$` when not in POSIX mode.
                # Per: https://www.gnu.org/software/bash/manual/bash.html#Shell-Functions-1
                fname = lib.escapeShellArg (lib.replaceString "$" "-" (lib.getName finalAttrs));
                inherit (finalAttrs.src) gitRepoUrl;
              in
              ''
                mkdir -p "$out/source"
                cp -rv * "$out/source"

                mkdir -p "$out/nix-support"
                cat <<EOF > "$out/nix-support/setup-hook"
                swiftPackageAddDep_${fname}() {
                  declare -g -A swiftpmDeps+=(["${gitRepoUrl}"]='$out/source')
                }
                prependToVar postUnpackHooks swiftPackageAddDep_${fname}
                EOF
              '';

            passthru.isSwiftPackage = true;
          };
        }
        // args.passthru or { };

      meta = lib.optionalAttrs (swift != null) {
        inherit (swift.meta) platforms;
      }
      // args.meta or { };
    };
}
