# shellcheck shell=bash

swiftpm_addCVars() {
    # See ../setup-hooks/role.bash
    # local role_post
    # getHostRoleEnvHook

    # TODO: Figure out how to make this work with cross-compilation
    swiftLibDir='.*/lib/swift\(_static\)?/\(linux\|macosx\|windows\)\(/[A-Za-z0-9_-]*$\)?'
    while IFS= read -d "" d; do
        # Only add the folder if it actually contains Swift modules.
        if [ -n "$(ls "$d"/*.swiftmodule)" ]; then
            appendToVar swiftpmFlags "-Xswiftc" "-I" "-Xswiftc" "$d"
        fi
    done < <(find "$1" -maxdepth 4 -type d -and -regex "$swiftLibDir" -print0)
}

addEnvHooks "$targetOffset" swiftpm_addCVars

swiftpmUnpackDeps() {
    echo "Unpacking SwiftPM dependencies"
    mkdir -p "$NIX_BUILD_TOP/$sourceRoot/.build"
    for dep in "${!swiftpmDeps[@]}"; do
      packageName=$(basename "$dep" .git)
      mkdir -p "$NIX_BUILD_TOP/$sourceRoot/Packages"
      ln -s "${swiftpmDeps[$dep]}" "$NIX_BUILD_TOP/$sourceRoot/Packages/$packageName"
      echo "{\"identity\": \"$packageName\", \"kind\": \"remoteSourceControl\", \"location\": \"$dep\"}"
    done | @jq@ --slurp '
        {
            "object": {
                "artifacts": [ ],
                "dependencies": [ .[] |
                    {
                        "basedOn": null,
                        "packageRef": {
                            "identity": .identity,
                            "kind": .kind,
                            "location": .location,
                            "name": .identity
                        },
                        "state": {
                            "name": "edited",
                            "path": null
                        },
                        "subpath": .identity
                    }
                ],
                "prebuilts": [ ],
            },
            "version": 7
        }
    ' > "$NIX_BUILD_TOP/$sourceRoot/.build/workspace-state.json"
}

appendToVar postUnpackHooks swiftpmUnpackDeps

# Build using 'swift-build'.
swiftpmBuildPhase() {
    runHook preBuild

    local buildCores=1
    if [ "${enableParallelBuilding-1}" ]; then
        buildCores="$NIX_BUILD_CORES"
    fi

    local flagsArray=(
        -j "$buildCores"
        -c "${swiftpmBuildConfig-release}"
        -Xswiftc -module-cache-path -Xswiftc "$NIX_BUILD_TOP/module-cache"
    )
    concatTo flagsArray swiftpmFlags swiftpmFlagsArray

    echoCmd 'SwiftPM flags' "${flagsArray[@]}"
    TERM=dumb swift-build --disable-sandbox "${flagsArray[@]}"

    runHook postBuild
}

if [ -z "${dontUseSwiftpmBuild-}" ] && [ -z "${buildPhase-}" ]; then
    buildPhase=swiftpmBuildPhase
fi

# Check using 'swift-test'.
swiftpmCheckPhase() {
    runHook preCheck

    local buildCores=1
    if [ "${enableParallelBuilding-1}" ]; then
        buildCores="$NIX_BUILD_CORES"
    fi

    local flagsArray=(
        -j "$buildCores"
        -c "${swiftpmBuildConfig-release}"
    )
    concatTo flagsArray swiftpmFlags swiftpmFlagsArray

    echoCmd 'check flags' "${flagsArray[@]}"
    TERM=dumb swift test "${flagsArray[@]}"

    runHook postCheck
}

if [ -z "${dontUseSwiftpmCheck-}" ] && [ -z "${checkPhase-}" ]; then
    checkPhase=swiftpmCheckPhase
fi

# Helper used to find the binary output path.
# Useful for performing the installPhase of swiftpm packages.
swiftpmBinPath() {
    local flagsArray=(
        -c "${swiftpmBuildConfig-release}"
    )
    concatTo flagsArray swiftpmFlags swiftpmFlagsArray

    swift-build --show-bin-path "${flagsArray[@]}"
}

# TODO: Only use install_name_tool on Darwin, support static libraries
swiftpmInstallPhase() {
    runHook preInstall

    local products=$(swiftpmBinPath)
    while IFS= read -d "" exe; do
        install -D -m 755 "$products/$exe" "${!outputBin}/bin/$exe"
    done < <(swift-package dump-package | @jq@ --raw-output0 '.products[] | select(.type | has("executable")) | .name')

    local libsToInstall=()
    local modulesToInstall=()

    while IFS= read -d "" library; do
        if [ -e "$products/lib$library@sharedLibrary@" ]; then
            install_name_tool "$products/lib$library@sharedLibrary@" \
               -id "${!outputLib}/lib/lib$library@sharedLibrary@"
            appendToVar libsToInstall "$products/lib$library@sharedLibrary@"
        fi
        if [ -e "$products/$library.swiftmodule" ]; then
            appendToVar modulesToInstall "$products/$library.swiftmodule"
        fi
        if [ -e "$products/Modules/$library.swiftmodule" ]; then
           appendToVar modulesToInstall "$products/Modules/$library.swiftmodule"
        fi
    done < <(swift-package dump-package | @jq@ --raw-output0 '.products[] | select(.type | has("library")) | .name')

    if [ -n "${libsToInstall}" ]; then
        install -D -t "${!outputLib}/lib" "${libsToInstall[@]}"
        # Only install modules if there are any library products.
        if [ -n "${modulesToInstall}" ]; then
            install -D -t "${!outputInclude}/lib/swift/@swiftPlatform@" "${modulesToInstall[@]}"
        fi
    fi

    runHook postInstall
}

if [ -z "${dontUseSwiftpmInstall-}" ] && [ -z "${installPhase-}" ]; then
    installPhase=swiftpmInstallPhase
fi
