//-----------------------------------------------------------------------------
// File: KeybdExc.cpp
//
// Desc: Demonstrates an application which receives immediate
//       keyboard data in exclusive mode. Here's how exclusive vs.
//       non-exclusive cooperative levels are explained in the DirectX
//       documentation:
//           "The fact that your application is using a device at the exclusive
//         level does not mean that other applications cannot get data from
//         the device. However, it does mean that no other application can
//         also acquire the device exclusively."
//           "When an application has exclusive access to the keyboard, it
//         suppresses all keyboard messages except CTRL+ALT+DEL and, on Windows
//         95 and Windows 98, ALT+TAB."
//           "DirectInput does not allow any application to have background
//         exclusive access to the keyboard. If it did, Windows would not have
//         access to the keyboard and the user would not even be able to use
//         CTRL+ALT+DELETE to restart the system."
//
// Copyright (c) 1998-1999 Microsoft Corporation. All rights reserved.
// Ported by Vadim Bodrov, TMT Development Corp.
//-----------------------------------------------------------------------------
unit keybdexc;
interface
uses Windows, Messages, Strings, DInput;

var
  g_bActive: Boolean              := TRUE;
  diks: array[0..255] of Byte;   // DirectInput keyboard state buffer

function InitDirectInput(Wnd: HWND): HResult;
function UpdateInputState(hDlg: HWND): HResult;
function FreeDirectInput: HResult;
function SetAcquire(hDlg: HWND): HResult;


implementation

//uses Windows, Messages, Strings, DInput;

              {         $r keybdexc.res}

//{{NO_DEPENDENCIES}}
// Microsoft Developer Studio generated include file.
// Used by KeybdExc.rc
//
{const
    IDI_MAIN                       = 102;
    IDD_KEYBD_EXC                  = 102;
    IDC_KEYBD_STATE                = 1000;
    IDC_CLOSE                      = 1001;}

// Next default values for new objects
//
{const
     _APS_NEXT_RESOURCE_VALUE      = 103;
     _APS_NEXT_COMMAND_VALUE       = 40001;
     _APS_NEXT_CONTROL_VALUE       = 1003;
     _APS_NEXT_SYMED_VALUE         = 101;}

//-----------------------------------------------------------------------------
// Global variables
//-----------------------------------------------------------------------------
var
   g_pDI: IDirectInput             := nil;
   g_pKeyboard: IDirectInputDevice := nil;
//   g_bActive: Boolean              := TRUE;




//-----------------------------------------------------------------------------
// Name: InitDirectInput()
// Desc: Initialize the DirectInput variables.
//-----------------------------------------------------------------------------
function InitDirectInput(Wnd: HWND): HResult;
begin
    // Register with the DirectInput 7 subsystem and get a pointer
    // to a IDirectInput interface we can use.
    Result := DirectInputCreate(GetWindowLong(Wnd, GWL_HINSTANCE),
                            $0700, g_pDI, nil);
    if FAILED(Result) then
        exit;

    // Obtain an interface to the system keyboard device.
    Result := g_pDI.CreateDevice(GUID_SysKeyboard, g_pKeyboard, nil);
    if FAILED(Result) then
        exit;

    // Set the data format to "keyboard format" - a predefined data format
    //
    // A data format specifies which controls on a device we
    // are interested in, and how they should be reported.
    //
    // This tells DirectInput that we will be passing an array
    // of 256 bytes to IDirectInputDevice::GetDeviceState.
    Result := g_pKeyboard.SetDataFormat(c_dfDIKeyboard);
    if FAILED(Result)then
        exit;

    // Set the cooperativity level to let DirectInput know how
    // this device should interact with the system and with other
    // DirectInput applications.
    Result := g_pKeyboard.SetCooperativeLevel(Wnd, DISCL_EXCLUSIVE or DISCL_FOREGROUND );

    if FAILED(Result) then
        exit;

    Result := S_OK;
end;




//-----------------------------------------------------------------------------
// Name: SetAcquire()
// Desc: Acquire or unacquire the keyboard, depending on if the app is active
//       Input device must be acquired before the GetDeviceState is called
//-----------------------------------------------------------------------------
function SetAcquire(hDlg: HWND): HResult;
begin
    // Nothing to do if g_pKeyboard is NULL
    if g_pKeyboard = nil then
    begin
        Result := S_FALSE;
        exit;
    end;

    if g_bActive then
        // Acquire the input device
        g_pKeyboard.Acquire
    else
    begin
        // Update the dialog text
//        SetWindowText( GetDlgItem( hDlg, IDC_KEYBD_STATE ), 'Unacquired' );

        // Unacquire the input device
        g_pKeyboard.Unacquire;
    end;

    Result := S_OK;
end;




//-----------------------------------------------------------------------------
// Name: UpdateInputState()
// Desc: Get the input device's state and display it.
//-----------------------------------------------------------------------------
function UpdateInputState(hDlg: HWND): HResult;
    var
//        diks: array[0..255] of Byte;   // DirectInput keyboard state buffer
        // Make a string of the index values of the keys that are down
{        strNewText: array[0..256*3] of Char;
        strTemp: String;}
        i: Longint;
        // Get the old text in the text box
{        strOldText: array[0..127] of Char;}
begin
    if g_pKeyboard <> nil then
    begin
        // Get the input's device state, and put the state in dims
        Result := g_pKeyboard.GetDeviceState(sizeof(diks), @diks);
        if FAILED(Result) then
        begin
            // DirectInput is telling us that the input stream has been
            // interrupted.  We aren't tracking any state between polls, so
            // we don't have any special reset that needs to be done.
            // We just re-acquire and try again.

            // If input is lost then acquire and keep trying
            Result := g_pKeyboard.Acquire;
            while (Result = DIERR_INPUTLOST) or (Result = E_ACCESSDENIED) do
                Result := g_pKeyboard.Acquire;

            if FAILED(Result) then
                exit;
        end;

//        strTemp := '';



(*        for i := 0 to 255 do
              if (diks[i] and $80) <> 0 then
                  strTemp +:= IntToHex(i, 2) + ' ';             *)




{                  strTemp +:= IntToHex(i, 2) + ' ';}





//        StrPCopy(strNewText, strTemp);

//        GetWindowText( GetDlgItem( hDlg, IDC_KEYBD_STATE ), strOldText, 127 );

        // If anything changed then repaint - avoid flicker
//        if 0 <> lStrCmp( strOldText, strNewText ) then
//            SetWindowText( GetDlgItem( hDlg, IDC_KEYBD_STATE ), strNewText );
    end;

    Result := S_OK;
end;




//-----------------------------------------------------------------------------
// Name: FreeDirectInput()
// Desc: Initialize the DirectInput variables.
//-----------------------------------------------------------------------------
function FreeDirectInput: HResult;
begin
    // Unacquire and release any DirectInputDevice objects.
    if g_pKeyboard <> nil then
    begin
        // Unacquire the device one last time just in case
        // the app tried to exit while the device is still acquired.
        g_pKeyboard.Unacquire;
        g_pKeyboard.Release;
        g_pKeyboard := nil;
    end;

    // Release any DirectInput objects.
    if g_pDI <> nil then
    begin
        g_pDI.Release;
        g_pDI := nil;
    end;

    Result := S_OK;
end;




//-----------------------------------------------------------------------------
// Name: MainDialogProc()
// Desc: Handles dialog messages
//-----------------------------------------------------------------------------
{function MainDialogProc conv arg_stdcall (hDlg: HWND; msg: UINT; wParam: WPARAM;
    lParam: LPARAM): LResult;
begin
    case msg  of
        WM_INITDIALOG:
        begin
            Result := InitDirectInput( hDlg );
            if FAILED(Result) then
            begin
                MessageBox( 0, 'Error Initializing DirectInput',
                            'DirectInput Sample', MB_ICONERROR or MB_OK );
                EndDialog( hDlg, 0 );
            end;

            // Set a timer to go off 12 times a second, to read input
            // Note: Typically an application would poll the keyboard
            //       much faster than this, but this slow rate is simply
            //       for the purposes of demostration
            SetTimer(hDlg, 0, 1000 div 12, nil);
            Result := 1;
            exit;
        end;

        WM_ACTIVATE:
        begin
            if WA_INACTIVE = wParam then
                g_bActive := FALSE
            else
                g_bActive := TRUE;

            // Set exclusive mode access to the mouse based on active state
            SetAcquire( hDlg );
            Result := 1;
            exit;
        end;

        WM_TIMER:
        begin
            // Update the input device every timer message
            if g_bActive then
            begin
                Result := UpdateInputState( hDlg );
                if FAILED(Result) then
                begin
                    KillTimer( hDlg, 0 );
                    MessageBox( 0, 'Error Reading Input State',
                                'DirectInput Sample', MB_ICONERROR or MB_OK );
                    EndDialog( hDlg, 1 );
                end;
            end;
        end;

        WM_COMMAND:
        begin
            if wParam = IDC_CLOSE then
                PostQuitMessage( 0 );

            Result := 1;
            exit;
        end;

        WM_CLOSE:
        begin
            KillTimer( hDlg, 0 );
            EndDialog( hDlg, 1 );
            Result := 1;
            exit;
        end;
    end;

    Result := 0;
end;      }




//-----------------------------------------------------------------------------
// Name: WinMain()
// Desc: Entry point for the application.  Since we use a simple dialog for
//       user interaction we don't need to pump messages.
//-----------------------------------------------------------------------------
begin
    // Display the main dialog box.
//    DialogBox( hInstance, MAKEINTRESOURCE(IDD_KEYBD_EXC), 0, @MainDialogProc );

//    FreeDirectInput;
end.