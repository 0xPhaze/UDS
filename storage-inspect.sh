#!/usr/bin/env bash
# adapted from https://github.com/nomad-xyz/monorepo/blob/main/scripts/storage-inspect.sh

set -e

if ! command -v forge &>/dev/null; then
    echo "forge could not be found. Please install forge by running:"
    echo "curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

contracts="${@:2}"
func=$1
file_ending=.storage-layout

if [[ $func == "check" ]]; then
    for contract in ${contracts[@]}; do
        layout_file="$contract$file_ending"
        new_layout_file="$contract.tmp$file_ending"
        forge inspect "$contract" storage-layout >>"$new_layout_file"
        if ! cmp -s $layout_file $new_layout_file; then
            echo "storage-layout test: fail ❌"
            echo "The following lines are different for $contract:"
            diff -a --suppress-common-lines "$layout_file" "$new_layout_file" ||
                rm $new_layout_file
            exit 1
        else
            echo "storage-layout test: pass ✅"
            rm $new_layout_file
            exit 0
        fi
    done
elif [[ $func == "generate" ]]; then
    for contract in ${contracts[@]}; do
        layout_file="$contract$file_ending"
        echo "Creating storage layout diagram for the contract: $contract"
        echo "..."
        forge inspect "$contract" storage-layout >>"$layout_file"
        echo "Storage layout snapshot stored at $layout_file"
    done
else
    echo "unknown command. Use 'generate' or 'check' as the first argument."
    exit 0
fi
