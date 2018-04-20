$paths = "\\cold.grcc.edu\SCCM\Drivers\Windows7\e31\quadro600\"

$xs = ls -Path $paths -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue 

Foreach ($x in $xs){
     pnputil -a $x.fullname
}