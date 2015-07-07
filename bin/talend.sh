#!/bin/bash

declare -r TALEND_CUSTOM_COMPONENTS="src/talend-components"
declare -r TALEND_WORKSPACE="src/talend-workspace"
declare -r TALEND_COMPONENTS_DOWNLOAD_URL="https://ci.aodn.org.au/job/talend_components_edge/lastSuccessfulBuild/artifact/directory-build/target/components-1.0.0-SNAPSHOT.zip"
declare -r HARVESTERS_GIT_REPO="git@github.com:aodn/harvesters.git"

# checkout the git repository containing harvesters
checkout_harvesters_git_repo() {
    if [ ! -d "src/harvesters/.git" ]; then
        mkdir -p src
        (cd src && git clone $HARVESTERS_GIT_REPO harvesters)
    fi
}

# download talend components (only if required)
download_talend_components() {
    if [ ! -d "$TALEND_CUSTOM_COMPONENTS" ]; then
        mkdir -p $TALEND_CUSTOM_COMPONENTS
        curl -o $TALEND_CUSTOM_COMPONENTS/components.zip "$TALEND_COMPONENTS_DOWNLOAD_URL"
        (cd $TALEND_CUSTOM_COMPONENTS && unzip components.zip && rm components.zip)
    else
        echo "---------------------------------------------------------------"
        echo "Talend components already exists in '$TALEND_CUSTOM_COMPONENTS'"
        echo "If you wish to download a new version of talend-components, delete '$TALEND_CUSTOM_COMPONENTS'"
        echo "---------------------------------------------------------------"
    fi

    echo "#################################################################"
    echo "talend-components will be at '/vagrant/$TALEND_CUSTOM_COMPONENTS'"
    echo "#################################################################"
}

# simply run talend
run_talend() {
    vagrant ssh po -- -X "cd /var/lib/talend && ./TOS_DI-linux-gtk-x86_64"
}

# main
main() {
    checkout_harvesters_git_repo
    download_talend_components
    run_talend
}

main "$@"
