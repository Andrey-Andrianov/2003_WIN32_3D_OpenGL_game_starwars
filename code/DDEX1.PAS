//-----------------------------------------------------------------------------
// File: DDEx1.CPP
//
// Desc: Direct Draw example program 1.  Creates a Direct Draw
//       object and then a primary surface with a back buffer.
//       Slowly flips between the primary surface and the back
//       buffer.  Press F12 to terminate the program.
//
// Copyright (c) 1995-1999 Microsoft Corporation. All rights reserved.
// Ported by Vadim Bodrov, TMT Development Corp.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Include files
//-----------------------------------------------------------------------------
unit ddex1;
interface
uses Windows, Messages, DDraw;

function InitApp(Instance: THandle; nCmdShow: Longint;wnd:hwnd): HResult;
procedure wnd_actitate(Wnd: HWND; message: UINT; wParam: WPARAM; lParam: LPARAM);

implementation

{$r ddex1.res}

const
    IDI_MAIN_ICON  = 101;
    IDR_MENU       = 102;
    IDM_EXIT       = 40001;


//-----------------------------------------------------------------------------
// Local definitions
//-----------------------------------------------------------------------------
const
    NAME            = 'DDExample1';
    TITLE           = 'Direct Draw Example 1';

//-----------------------------------------------------------------------------
// Default settings
//-----------------------------------------------------------------------------
const
     TIMER_ID       = 1;
     TIMER_RATE     = 500;

//-----------------------------------------------------------------------------
// Global data
//-----------------------------------------------------------------------------
var
    g_pDD:         IDirectDraw7 := nil;          // DirectDraw object
    g_pDDSPrimary: IDirectDrawSurface7 := nil;   // DirectDraw primary surface
    g_pDDSBack:    IDirectDrawSurface7 := nil;   // DirectDraw back surface
    g_bActive:     Boolean := FALSE;             // Is application active?

//-----------------------------------------------------------------------------
// Local data
//-----------------------------------------------------------------------------
var
    szMsg: PChar      := 'Page Flipping Test: Press F12 to exit';
    szFrontMsg: PChar := 'Front buffer (F12 to quit)';
    szBackMsg: PChar  := 'Back buffer (F12 to quit)';



//-----------------------------------------------------------------------------
// Name: ReleaseAllObjects()
// Desc: Finished with all objects we use; release them
//-----------------------------------------------------------------------------
procedure ReleaseAllObjects;
begin
    if g_pDD  <> nil then
    begin
        if g_pDDSPrimary <> nil then
        begin
            g_pDDSPrimary.Release;
            g_pDDSPrimary := nil;
        end;
        g_pDD.Release;
        g_pDD := nil;
    end;
end;




//-----------------------------------------------------------------------------
// Name: InitFail()
// Desc: This function is called if an initialization function fails
//-----------------------------------------------------------------------------
function InitFail(Wnd: HWND; hRet: HREsult; szError: LPCTSTR): HResult;
begin
    ReleaseAllObjects;
    MessageBox(Wnd, szError, TITLE, MB_OK);
    DestroyWindow(Wnd);
    Result := hRet;
end;


var
    phase: Byte := 0;

//-----------------------------------------------------------------------------
// Name: UpdateFrame()
// Desc: Displays the proper text for the page
//-----------------------------------------------------------------------------
procedure UpdateFrame(Wnd: HWND);
var
    dc:      HDC;
    ddbltfx: TDDBltFX;
    rc:      TRect;
    size:    TSize;
begin
    // Use the blter to do a color fill to clear the back buffer
    ZeroMemory(@ddbltfx, sizeof(ddbltfx));
    ddbltfx.dwSize := sizeof(ddbltfx);
    ddbltfx.dwFillColor := 0;
    g_pDDSBack.Blt(nil, nil, nil, DDBLT_COLORFILL or DDBLT_WAIT, @ddbltfx);

    if g_pDDSBack.GetDC(dc) = DD_OK then
    begin
        SetBkColor(dc, RGB(0, 0, 255));
        SetTextColor(dc, RGB(255, 255, 0));
        if phase <> 0 then
        begin
            GetClientRect(Wnd, rc);
            GetTextExtentPoint(dc, szMsg, lstrlen(szMsg), size);
            TextOut(dc, (rc.right - size.cx) div 2, (rc.bottom - size.cy) div 2,
                    szMsg, lstrlen(szMsg));
            TextOut(dc, 0, 0, szFrontMsg, lstrlen(szFrontMsg));
            phase := 0;
        end else
        begin
            TextOut(dc, 0, 0, szBackMsg, lstrlen(szBackMsg));
            phase := 1;
        end;
        g_pDDSBack.ReleaseDC(dc);
    end;
end;




//-----------------------------------------------------------------------------
// Name: WindowProc()
// Desc: The Main Window Procedure
//-----------------------------------------------------------------------------
function WindowProc conv arg_stdcall (Wnd: HWND; message: UINT; wParam: WPARAM; lParam: LPARAM): LResult;
var
    hRet: HResult;
begin
    case message of
        WM_ACTIVATE:
        begin
            // Pause if minimized
            g_bActive := not Boolean(HIWORD(wParam));
            Result := 0;
            exit;
        end;

        WM_DESTROY:
        begin
            // Clean up and close the app
            ReleaseAllObjects;
            PostQuitMessage(0);
            Result := 0;
            exit;
        end;

        WM_KEYDOWN:
        begin
            // Handle any non-accelerated key commands
            if wParam in [VK_ESCAPE, VK_F12] then
            begin
                    PostMessage(Wnd, WM_CLOSE, 0, 0);
                    Result := 0;
                    exit;
            end;
        end;

        WM_SETCURSOR:
        begin
            // Turn off the cursor since this is a full-screen app
            SetCursor(0);
            Result := 1;
            exit;
        end;

        WM_TIMER:
        begin
            // Update and flip surfaces
            if g_bActive and (TIMER_ID = wParam) then
            begin
                UpdateFrame(Wnd);
                while (TRUE) do
                begin
                    hRet := g_pDDSPrimary.Flip(nil, 0);
                    if hRet = DD_OK then
                        break;
                    if hRet = DDERR_SURFACELOST then
                    begin
                        hRet := g_pDDSPrimary.Restore;
                        if hRet <> DD_OK then
                            break;
                    end;
                    if hRet <> DDERR_WASSTILLDRAWING then
                        break;
                end;
            end;
        end;(**)
    end;
    Result := DefWindowProc(Wnd, message, wParam, lParam);
end;


procedure wnd_actitate(Wnd: HWND; message: UINT; wParam: WPARAM; lParam: LPARAM);
        begin
            // Pause if minimized
            g_bActive := not Boolean(HIWORD(wParam));
//            Result := 0;
            exit;
        end;

//-----------------------------------------------------------------------------
// Name: InitApp()
// Desc: Do work required for every instance of the application:
//          Create the window, initialize data
//-----------------------------------------------------------------------------
function InitApp(Instance: THandle; nCmdShow: Longint;wnd:hwnd): HResult;
var
//    Wnd:    HWND;
//    wc:      TWndClass;
    ddsd:    TDDSurfaceDesc2;
    ddscaps: TDDSCaps2;
    hRet:    HResult;
begin
(*    // Set up and register window class
    wc.style := CS_HREDRAW or CS_VREDRAW;
    wc.lpfnWndProc := @WindowProc;
    wc.cbClsExtra := 0;
    wc.cbWndExtra := 0;
    wc.hInstance := Instance;
    wc.hIcon := LoadIcon(Instance, MAKEINTRESOURCE(IDI_MAIN_ICON));
    wc.hCursor := LoadCursor(0, IDC_ARROW);
    wc.hbrBackground := GetStockObject(BLACK_BRUSH);
    wc.lpszMenuName := NAME;
    wc.lpszClassName := NAME;
    RegisterClass(wc);

    // Create a window
    Wnd := CreateWindowEx(WS_EX_TOPMOST,
                          NAME,
                          TITLE,
                          WS_POPUP,
                          0,
                          0,
                          GetSystemMetrics(SM_CXSCREEN),
                          GetSystemMetrics(SM_CYSCREEN),
                          0,
                          0,
                          Instance,
                          nil);
    if Wnd = 0 then
    begin
        Result := 0;
        exit;
    end;
    ShowWindow(Wnd, nCmdShow);
    UpdateWindow(Wnd);
    SetFocus(Wnd);*)

    ///////////////////////////////////////////////////////////////////////////
    // Create the main DirectDraw object
    ///////////////////////////////////////////////////////////////////////////
    hRet := DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);
    if hRet <> DD_OK then
    begin
        Result := InitFail(Wnd, hRet, 'DirectDrawCreateEx FAILED');
        exit;
    end;

    // Get exclusive mode
    hRet := g_pDD.SetCooperativeLevel(Wnd, DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN);
    if hRet <> DD_OK then
    begin
        Result := InitFail(Wnd, hRet, 'SetCooperativeLevel FAILED');
        exit;
    end;

    // Set the video mode to 640x480x8
    hRet := g_pDD.SetDisplayMode(640, 480, 16, 0, 0);
    if hRet <> DD_OK then
    begin
        Result := InitFail(Wnd, hRet, 'SetDisplayMode FAILED');
        exit;
    end;

    // Create the primary surface with 1 back buffer
    ZeroMemory(@ddsd, sizeof(ddsd));
    ddsd.dwSize := sizeof(ddsd);
    ddsd.dwFlags := DDSD_CAPS or DDSD_BACKBUFFERCOUNT;
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_FLIP or
                           DDSCAPS_COMPLEX;
    ddsd.dwBackBufferCount := 1;
    hRet := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
    if hRet <> DD_OK then
    begin
        Result := InitFail(Wnd, hRet, 'CreateSurface FAILED');
        exit;
    end;

    // Get a pointer to the back buffer
    ZeroMemory(@ddscaps, sizeof(ddscaps));
    ddscaps.dwCaps := DDSCAPS_BACKBUFFER;
    hRet := g_pDDSPrimary.GetAttachedSurface(ddscaps, g_pDDSBack);
    if hRet <> DD_OK then
    begin
        Result := InitFail(Wnd, hRet, 'GetAttachedSurface FAILED');
        exit;
    end;

    // Create a timer to flip the pages
    if TIMER_ID <> SetTimer(Wnd, TIMER_ID, TIMER_RATE, nil) then
    begin
        Result := InitFail(Wnd, hRet, 'SetTimer FAILED');
        exit;
    end;

    Result := DD_OK;
end;




//-----------------------------------------------------------------------------
// Name: WinMain()
// Desc: Initialization, message loop
//-----------------------------------------------------------------------------
(*var
   msg: TMsg;
begin
    if InitApp(hInstance, CmdShow) <> DD_OK then
        halt(0);

    while GetMessage(msg, 0, 0, 0) do
    begin
        TranslateMessage(msg);
        DispatchMessage(msg);
    end;*)
end.