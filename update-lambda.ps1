
[CmdletBinding()]
Param ( [Parameter(Mandatory=$True,Position=1)]
 [string] $ProjectName)

 $CurrentDir = (Get-Item -Path "./" -Verbose).FullName
 $DateSuffix = (get-date -format "yyyy-MM-dd-HM")
 $BUCKET="tci-repo-devaws-telus-com"
 $PREFIX="lambdatest"
 $TEMPDEPLOY = $CurrentDir + "\"+ $ProjectName + "\tempDeploy"
 
write-host "Creating the temp VirtualEnv"
if (Test-Path $TEMPDEPLOY){
    Remove-Item -force -r $TEMPDEPLOY
}

virtualenv $TEMPDEPLOY

if (!(Test-Path $TEMPDEPLOY)){

    write-host "PATH NOT FOUND!"$TEMPDEPLOY
    write-host "Aborting script... Something wrong with virtualenv...."
    Exit
}
write-host "Copying Lambda project"
$source = $CurrentDir+"\"+$ProjectName+"\*.*"
Copy-Item -PATH $source -Destination $TEMPDEPLOY

 if (!(Test-Path ($TEMPDEPLOY+"\lambda_function.py"))){

    write-host "Could not find lambda_function.py in $TEMPDEPLOY"
    Exit
 }

 if (Test-Path ($TEMPDEPLOY+"\code.zip")){
  rm ($TEMPDEPLOY+"\code.zip")

 } 
 # Installing Packages
 write-host "Installing Packages"
&($TEMPDEPLOY+"\Scripts\pip") install pip -U
if (Test-Path (${TEMPDEPLOY}+"/requirements.txt")) {
    &($TEMPDEPLOY+"\Scripts\pip") install pip -r "$TEMPDEPLOY\requirements.txt"
}
# Adding Packages to the Zip File
cd ($TEMPDEPLOY+"\lib\site-packages")
zip -r9q ($TEMPDEPLOY+"\code.zip") *.*

cd $TEMPDEPLOY
zip -g ($TEMPDEPLOY+"\code.zip") lambda_function.py

write-host "Zip Completed"

#Copying to S3
write-host "Copying to S3"
aws s3 cp code.zip ("s3://"+$BUCKET+"/"+$PREFIX+"/"+$ProjectName+"-"+$DateSuffix+".zip")

aws lambda update-function-code --function-name $ProjectName --s3-key ($PREFIX+"/"+$ProjectName+"-"+$DateSuffix+".zip")--s3-bucket $BUCKET > ($TEMPDEPLOY+"/update.log") 

if (Test-Path (($TEMPDEPLOY+"\update.log"))){
  Get-Content ($TEMPDEPLOY+"\update.log")
}
write-host "Function updated"
