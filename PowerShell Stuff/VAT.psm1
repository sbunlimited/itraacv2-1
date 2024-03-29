function forvat 
{
  $ErrorActionPreference = "Stop" #i couldn't get foreach-object -ErrorAction or anything else to take over... basically just want the first error to stop the loop rather than banging it's head through all the servers
  $stuff = $args #apparently args gets wiped out going through the pipeline
  "BA,BR,GA,GE,GR,HD,HO,IL,KA,KL,LU,MA,MI,PU,RA,SF,SN,SP,ST,WI,DEV".split(",") | foreach-object {
    write-host -nonewline "executing $_... "
    invoke-expression "$stuff" 
  }
  $ErrorActionPreference = "Continue"
}

# e.g.: forvatsql -Q `"print `''$_'`'`"
# e.g.: forvatsql -i file.sql
function forvatsql
{
  forvat "sqlcmd -S mwr-tro-`$_\mssql2008 -d iTRAAC $args"
}
