#*****************************************************************************#
#************************** Developed by: RonalSLCH **************************#
#*****************************************************************************#

*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault

*** Variables ***
${sRobotWebsiteURL}=    https://robotsparebinindustries.com/#/robot-order
${sReceiptsFolder}=    ${OUTPUT_DIR}${/}Receipts
${sScreenshotsFolder}=    ${OUTPUT_DIR}${/}Screenshots

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create folders
    Open the robot order website
    ${cSecret}=    Get Secret    Secrets
    Show URL    ${cSecret}[sOrdersFileURL]
    ${sOrdersFileURL}=    Input URL Dialog
    ${tOrders}=    Download and read the orders file    ${sOrdersFileURL}
    FOR    ${rOrder}    IN    @{tOrders}
        Close the annoying modal
        Fill the form    ${rOrder}
        Click Button    preview
        Wait Until Keyword Succeeds    10x    1s    Submit the order
        ${sPDFPath}=    Store the receipt as a PDF file    ${rOrder}[Order number]
        ${sScreenshotPath}=    Take a screenshot of the robot    ${rOrder}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${sScreenshotPath}    ${sPDFPath}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Close All Pdfs
    Close Browser and Remove files

*** Keywords ***
Create folders
    Create Directory    ${sReceiptsFolder}
    Create Directory    ${sScreenshotsFolder}

Open the robot order website
    Open Available Browser    ${sRobotWebsiteURL}

Download and read the orders file
    [Arguments]    ${sOrdersFileURL}
    Download    ${sOrdersFileURL}    overwrite=True
    ${tOrders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${tOrders}

Close the annoying modal
    Click Button    //button[@class="btn btn-dark"]

Fill the form
    [Arguments]    ${rOrder}
    Select From List By Value    //select[@id="head"]    ${rOrder}[Head]
    Select Radio Button    body    ${rOrder}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${rOrder}[Legs]
    Input Text    //input[@id="address"]    ${rOrder}[Address]

Submit the order
    Click Button    order
    Wait Until Element Is Visible    id:order-another    1

Store the receipt as a PDF file
    [Arguments]    ${sOrderNo}
    ${sReceiptHTML}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${sPDF}    ${sReceiptsFolder}${/}${sOrderNo}.pdf
    Html To Pdf    ${sReceiptHTML}    ${sPDF}
    [Return]    ${sPDF}

Take a screenshot of the robot
    [Arguments]    ${sOrderNo}
    Set Local Variable    ${sScreenshot}    ${sScreenshotsFolder}${/}${sOrderNo}.png
    Screenshot    //div[@id="robot-preview-image"]    ${sScreenshot}
    [Return]    ${sScreenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${sScreenshot}    ${sPDF}
    Open Pdf    ${sPDF}
    ${sImage}=    Create List    ${sScreenshot}:align=center
    Add Files To Pdf    ${sImage}    ${sPDF}    append=True

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${sReceiptsFolder}    ${OUTPUT_DIR}${/}Receipts.zip

Input URL Dialog
    Add heading    RobotSpareBin Industries Inc. Assistant    size=Small
    Add text input    url    label=Paste here the link you copied in the previous window:
    ${sOrdersFileURL}=    Run dialog
    [Return]    ${sOrdersFileURL.url}

Show URL
    [Arguments]    ${sOrdersFileURL}
    Add heading    Hello! Please copy this link and close the window.    size=Small
    Add heading    ${sOrdersFileURL}    size=Small
    Run dialog

Close Browser and Remove files
    Close Browser
    Remove Directory    ${sReceiptsFolder}    recursive=True
    Remove Directory    ${sScreenshotsFolder}    recursive=True
    Remove File    orders.csv
