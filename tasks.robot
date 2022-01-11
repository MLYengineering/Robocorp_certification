# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium      auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           OperatingSystem
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
#Library           RPA.Robocorp.Vault

# +
*** Variables*** 
${url}              https://robotsparebinindustries.com/#/robot-order
${url_orders}       https://robotsparebinindustries.com/orders.csv
${file_orders}      ${CURDIR}${/}orders.csv
${output_folder}    ${CURDIR}${/}Output
${image_folder}     ${CURDIR}${/}Image




# +
*** Keywords ***
Create folders
    Create Directory    ${output_folder}
    Empty Directory     ${output_folder}
    Create Directory    ${image_folder}
    Empty Directory     ${image_folder}


Get orders
    Download    url=${url_orders}    target_file=${file_orders}  overwrite=True
    ${table}    Read table from CSV   path=${file_orders} 
    [Return]  ${table} 

Open the intranet website  
    Open Available Browser  url=${url} 

Click form
    Click Button    OK
    
Fill the form  
    [Arguments]    ${row}
    Set Local Variable    ${legs}   xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Wait Until Element Is Enabled   //*[@id="head"]    
    Select From List By Value       //*[@id="head"]     ${row}[Head]
    Select Radio Button             body                ${row}[Body]
    Input Text                      ${legs}             ${row}[Legs]
    Input Text                      address             ${row}[Address]

Preview the robot
    Click Button    Preview
    Wait Until Element Is Visible   //*[@id="robot-preview-image"]
    #Set Browser Implicit Wait    2

    
Submit the order
    Click Button    order
    Wait Until Element Is Visible   id:order-another
    
Go to order another robot
    Click Button    order-another
    
Take a screenshot of the robot
    [Arguments]    ${Order number}
    Set Local Variable      ${image_file_name}      ${image_folder}${/}${Order number}.png
    Capture Element Screenshot      id:robot-preview-image      ${image_file_name}   
    [Return]    ${image_file_name} 
    
Store the receipt as a PDF file  
    [Arguments]    ${Order number}
    Set Local Variable      ${output_file_name}      ${output_folder}${/}${Order number}.pdf
    ${recepit_robot}=    Get Element Attribute    id:receipt  outerHTML
    Html To Pdf    ${recepit_robot}    ${output_file_name}  
    [Return]    ${output_file_name} 
    
    
Embed the robot screenshot to the receipt PDF file 
    [Arguments]     ${pdf}     ${screenshot} 
    @{pdfembedded}=       Create List     ${pdf}:x=0,y=0
    Add Files To PDF    ${pdfembedded}    ${screenshot}     ${True}

Zip the pdfs
    Archive Folder With Zip  ${CURDIR}${/}Output  receipts.zip
    
Customer mail
    Add heading             Welcome to satisfying robots
    Add text input          customer    label=What's your customer mail address    placeholder=Enter your mail adress here
    ${result}=              Run dialog
    [Return]    ${result.customer}
    
    
Display the success dialog
    [Arguments]   ${customer}
    ${secretpayment}     Get Secret   Payment   
    Add icon      Success
    Add heading   Your orders have been processed
    Add text      Dear ${customer} - all orders have been processed. Delivery will take some time.
    Add text      The following bank account will be used for payment:
    Add text      ${secretpayment}[bankaccount]
    Run dialog    title=Success


# +
*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    ${customer}=    Customer mail
    #Set Local Variable      ${customer}         dummy@vault.de
    ${orders}=    Get orders
    Create folders
    Open the intranet website
    FOR     ${row}     IN      @{orders}
        Click form
        Fill the form   ${row}
        Wait Until Keyword Succeeds     20x     2s    Preview the robot
        Wait Until Keyword Succeeds     20x     2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Zip the pdfs
    Close Browser
    Display the success dialog      ${customer}

    

    
    
    
    



# -


