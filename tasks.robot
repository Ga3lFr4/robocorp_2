*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Launch Website
    ${file}=    Ask for Excel URL
    Download Excel File    ${file}
    ${excel_data}=    Get Excel Data
    FOR    ${robot}    IN    @{excel_data}
        Dismiss Pop Up
        Fill Form Info    ${robot}
        Wait Until Keyword Succeeds    99x    0.1    Click Submit
        ${pdf_temp}=    Store Receipt    ${robot}[Order number]
        ${screenshot_temp}=    Screenshot Robot    ${robot}[Order number]
        Embed Screenshot to PDF    ${pdf_temp}    ${screenshot_temp}
        Click Order Another
    END
    ZIP PDF to output
    [Teardown]    Close Browser


*** Keywords ***
Launch Website
    ${robot_url}=    Get Secret    Orders_Robot_URL
    Open Available Browser    ${robot_url}[url]

Dismiss Pop Up
    Click Button    OK

Ask for Excel URL
    Add heading    Link to Excel File
    Add text input    file    label=Provide the link to the Orders file (.csv)
    ${result}=    Run dialog
    RETURN    ${result.file}

Download Excel File
    [Arguments]    ${url}
    Download    ${url}    overwrite=True

Get Excel Data
    ${excel_data}=    Read table from CSV    orders.csv    header=True
    RETURN    ${excel_data}

Fill Form Info
    [Arguments]    ${robot}
    Select From List By Value    head    1    ${robot}[Head]
    Select Radio Button    body    ${robot}[Body]
    Input Text    //input[@type='number']    ${robot}[Legs]
    Input Text    id:address    ${robot}[Address]
    Click Button    Preview

Click Submit
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt

Click Order Another
    Click Button    id:order-another

Store Receipt
    [Arguments]    ${filename}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}${filename}_receipt.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}${filename}_receipt.pdf

Screenshot Robot
    [Arguments]    ${filename}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}${filename}_screenshot
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}${filename}_screenshot

Embed Screenshot to PDF
    [Arguments]    ${pdf}    ${screenshot}
    Open Pdf    ${pdf}
    ${list}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To Pdf    ${list}    ${pdf}
    Close All Pdfs

ZIP PDF to output
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}
