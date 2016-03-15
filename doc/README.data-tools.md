# Data management tools

These tools are available in the production environment for 

## Bulk Async Upload

Upload many files asynchronously by piping them to
`async-upload.py`.

Example usage for a single file:
```
$ echo "SRC DST" | async-upload.py
$ echo "/tmp/IMOS_ACORN_V_20100716T060000Z_BONC_FV00_sea-state.n IMOS/ACORN/vector/BONC/2010/07/16/IMOS_ACORN_V_20100716T060000Z_BONC_FV00_sea-state.nc" | async-upload.py
```

Uploading multiple files:
```
$ find . -type f | cut -c3- | awk -v pwd=$PWD '{print pwd"/"$1 " " "IMOS/"$1}'
/tmp/ABOS_SOFS/ff/d/e/file2 IMOS/d/e/file2
/tmp/ABOS_SOFS/ff/file3 IMOS/file3
/tmp/ABOS_SOFS/ff/a/b/c/file1 IMOS/a/b/c/file1

$ find . -type f | cut -c3- | awk -v pwd=$PWD '{print pwd"/"$1 " " "IMOS/"$1}' | async-upload.py
```


## Talend

`talend_liqui` triggers a harvester with a pseudo file and triggers liquibase for it. Example usage:
```
$ talend_liqui<TAB><TAB>
$ talend_liqui srs_sst-srs_sst
```
