$SCRIPT_VERSION = "0.0.1"

# Import helper functions
. "$PSScriptRoot\Helper\Logging.ps1"
. "$PSScriptRoot\Helper\Settings.ps1" 

Initialize-Log -WriteToFile $true
Write-StartMessage $SCRIPT_VERSION
# ---------   Add new Site Column to Content Type ---------


 $web=Get-PnPWeb 

# Create new Site Column
Write-LoggedMessage -Text $("Working on site $($web.Title)")


$clientContext = Get-PnPContext


$CTContractD  = Run "Fetching Contract document for retention docntent type" { Get-PnPContentType -Identity "0x010100D45E6E72D8714CC7944D4D047D7ED38D"} # Contract document for retention

$CTContractDS=Run "Fetching content contract document set for retention" {Get-PnPContentType -Identity "0x0120D52000B1F22482248944C7B4616DE2B7BEF2E0"} #  Contract document set for retention

#$fields=$web.Fields

$clientContext.Load($CTContractDS)

$clientContext.Load($CTContractD)

Run "Loading web fields" {$clientContext.Load($web.Fields)}



Run "Executing load content type query" {$clientContext.ExecuteQuery}

$field= Run "Adding field <field name>" {Add-PnPField -Type Text -InternalName "ProvisionTextColumn1" -DisplayName "Test Column1" -Required}

Run "Adding field <field name> to content type <CT name>" {Add-PnPFieldToContentType -Field "ProvisionTextColumn1" -ContentType "Contract document set for retention" -Required}

Add-PnPFieldToContentType -Field "ProvisionTextColumn1" -ContentType "Contract document for retention" -Required


$CTContractD.Update(1)

$CTContractDS.Update(1)


Run "Executing udpate content type query" {$clientContext.ExecuteQuery()}


## ------------------------------------- END -----------------



# Create new Content Type based on Document ---------------------

$ctParent = Get-PnPContentType -Identity 0x0101

$newCT=Add-PnPContentType -Name "Document or Email1" -Description "BLABLA" -Group "Provisioning CT" -ParentContentType $ctParent

Add-PnPFieldToContentType -Field "ProvisionTextColumn" -ContentType $newCT.Id.StringValue


#  --------------------------------------------------------------


# Replace File with CT "Dokument" with the CT "Document or Email"


Add-PnPContentTypeToList -List "Dokumente" -ContentType  $newCT.Id.StringValue

$items=Get-PnPListItem -List "Dokumente" -Query "<View><Query><Where><Eq><FieldRef Name='ContentType'/><Value Type='Computed'>Dokument</value></Eq></Where></Query></View>"

foreach($item in $items){

Set-PnPListItem  -List "Dokumente" -Identity $item -ContentType $newCT.Id.StringValue

}

Remove-PnPContentTypeFromList -List "Dokumente" -ContentType 0x0101


#------------------------------------------------------------------------------




## Add Choice Information to Site COlumn


$ContractType = Get-PnPField  "ContractType"


$ContractType.Choices+= @("CDE","FGH")

$ContractType.UpdateAndPushChanges($true);

invoke-pnpQuery



# .................... Change RE ORDER ------------



$FieldlOrder = @("a_c","a_a","a_b")


$ContentTypeUpdate = Get-PnPContentType -Identity 0x010100D47CE0E00CB5CD4CBF575E2461B834E5

$FieldLinks = Get-PnPProperty -ClientObject $ContentTypeUpdate -Property "FieldLinks"

$FieldLinks.Reorder($FieldlOrder)

$ContentTypeUpdate.Update($True)

Invoke-PnPQuery




#  -----------------------------------------------------


$listUpdate = Get-PnPList "Dokumente"

$FieldLinks = Get-PnPProperty -ClientObject $listUpdate -Property "FieldLinks"





$array=New-Object System.Collections.Generic.List[Microsoft.Sharepoint.Client.ContentTypeId]

$ListContentType=$listUpdate.ContentTypes

Invoke-PnPQuery

$ctList=$list.ContentTypes | where {$_.Name -eq $newCT.Name}

$array.Add($ctList.Id)

$list.RootFolder.UniqueContentTypeOrder=$array

$list.RootFolder.Update()

$listUpdate.Update()

Invoke-PnPQuery

$democt=Get-PnPContentType -Identity 0x010100EE6C9813E8752C418CA65965DFCA7670006B1AC428AE3E9F4BB8E9CCB05C8B0D06 -List "Dokumente"


$list=$Web.Lists.GetById("e25da32e-aff4-4aa8-b030-929a27bc4e6b")

$clientContext.Load($list)

$clientContext.Load($list.ContentTypes)

Invoke-PnPQuery

$clientContext.ExecuteQuery()