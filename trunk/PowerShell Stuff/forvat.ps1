function forvat 
{
    $stuff = $args
    write-host $stuff
    "BA,BR,WI,HD,HO".split(",") | foreach-object { invoke-expression( "$stuff" ) }
}

# e.g.: forvatsql -Q `"print `''$_'`'`"
function forvatsql
{
    forvat "sqlcmd -S `$_\mssql2008 -d iTRAAC $args"
}
