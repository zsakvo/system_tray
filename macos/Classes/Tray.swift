import FlutterMacOS

let kInitSystemTray = "InitSystemTray"
let kSetSystemTrayInfo = "SetSystemTrayInfo"
let kSetContextMenu = "SetContextMenu"
let kPopupContextMenu = "PopupContextMenu"
let kSetPressedImage = "SetPressedImage"
let kGetTitle = "GetTitle"
let kDestroySystemTray = "DestroySystemTray"

private let kDefaultSizeWidth = 18
private let kDefaultSizeHeight = 18

private let kTitleKey = "title"
private let kIconPathKey = "iconpath"
private let kToolTipKey = "tooltip"
private let kIsTemplateKey = "is_template"
private let kTrayWidthKey = "tray_width"
private let kIsDualKey = "is_dual"
private let kUpTextKey = "up_text"
private let kDownTextKey = "down_text"

private let kSystemTrayEventClick = "click"
private let kSystemTrayEventRightClick = "right-click"
private let kSystemTrayEventDoubleClick = "double-click"

private let kSystemTrayEventCallbackMethod = "SystemTrayEventCallback"

class Tray: NSObject, NSMenuDelegate {
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    
    weak var menuManager: MenuManager?
    
    var statusItem: NSStatusItem?
    
    var contextMenuId: Int?
    
    init(
        _ registrar: FlutterPluginRegistrar, _ channel: FlutterMethodChannel,
        _ menuManager: MenuManager?
    ) {
        self.registrar = registrar
        self.channel = channel
        self.menuManager = menuManager
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case kInitSystemTray:
            initSystemTray(call, result)
        case kSetSystemTrayInfo:
            setTrayInfo(call, result)
        case kSetContextMenu:
            setContextMenu(call, result)
        case kPopupContextMenu:
            popUpContextMenu(call, result)
        case kSetPressedImage:
            setPressedImage(call, result)
        case kGetTitle:
            getTitle(call, result)
        case kDestroySystemTray:
            destroySystemTray(call, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        statusItem?.menu = nil
    }
    
    @objc func onSystemTrayEventCallback(sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            switch event.type {
            case .leftMouseUp:
                channel.invokeMethod(kSystemTrayEventCallbackMethod, arguments: kSystemTrayEventClick)
            case .rightMouseUp:
                channel.invokeMethod(kSystemTrayEventCallbackMethod, arguments: kSystemTrayEventRightClick)
            default:
                break
            }
        }
    }
    
    func setDualTitle(
        base64Icon:String?,
        upText:String,
        downText:String,width:CGFloat,
        statusItem:NSStatusItem?
    ){
        
        let DualStatusItemView = DualStatusItemView(frame: NSRect(x: 0, y: 0, width:width
                                                                  , height: 22))
        
        if let base64Icon = base64Icon {
            if let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters),
               let itemImage = NSImage(data: imageData)
            { 
                DualStatusItemView.image = itemImage
            }}
        
        DualStatusItemView.upText = upText
        DualStatusItemView.downText = downText
        
        
        statusItem?.button?.subviews.forEach { $0.removeFromSuperview() }
        statusItem?.button?.image = nil
        statusItem?.button?.title = ""
        statusItem?.length = width
        statusItem?.button?.addSubview(DualStatusItemView)
        
    }
    
    func initSystemTray(_ call: FlutterMethodCall, _ result: FlutterResult) {
        let arguments = call.arguments as! [String: Any]
        let title = arguments[kTitleKey] as? String
        let base64Icon = arguments[kIconPathKey] as? String
        let toolTip = arguments[kToolTipKey] as? String
        let isTemplate = arguments[kIsTemplateKey] as? Bool
        let trayWidth = arguments[kTrayWidthKey] as? Float
        let isDual = arguments[kIsDualKey] as? Bool ?? false
        let upText = arguments[kUpTextKey] as? String
        let downText = arguments[kDownTextKey] as? String
        
        // let isDual = true
        // let upText = "12.2644344 MB/s"
        // let downText = "32 KB /s"
        
        if statusItem != nil {
            result(false)
            return
        }
        
        // statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // statusItem = NSStatusBar.system.statusItem(
        //   withLength: trayWidth == nil ? NSStatusItem.variableLength : CGFloat(trayWidth!)
        // )
        
        let maxAutoWidth = Float(max(upText?.count ?? 0 , downText?.count ?? 0 ) * 9 + 5
        )
        
        statusItem = NSStatusBar.system.statusItem(
            withLength: trayWidth == nil ? isDual ? CGFloat(maxAutoWidth) : NSStatusItem.variableLength : CGFloat(trayWidth!)
        )
        
        statusItem?.button?.action = #selector(onSystemTrayEventCallback(sender:))
        statusItem?.button?.target = self
        statusItem?.button?.sendAction(on: [
            .leftMouseUp, .leftMouseDown, .rightMouseUp, .rightMouseDown,
        ])
        
        if let toolTip = toolTip {
            statusItem?.button?.toolTip = toolTip
        }
        
        // if let title = title {
        //   statusItem?.button?.title = title
        // }
        
        if(isDual){
            setDualTitle(base64Icon: base64Icon, upText: upText!, downText: downText!, width: CGFloat(trayWidth ?? maxAutoWidth ), statusItem:statusItem)
        }else{
            if let title = title {
                statusItem?.button?.title = title
            }
            if let base64Icon = base64Icon {
                if let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters),
                   let itemImage = NSImage(data: imageData)
                {
                    let destSize = NSSize(width: kDefaultSizeWidth, height: kDefaultSizeHeight)
                    itemImage.size = destSize
                    itemImage.isTemplate = isTemplate ?? false
                    statusItem?.button?.image = itemImage
                    statusItem?.button?.imagePosition = NSControl.ImagePosition.imageLeft
                    
                }
            }
        }
        
        
        
        result(true)
    }
    
    func setTrayInfo(_ call: FlutterMethodCall, _ result: FlutterResult) {
        let arguments = call.arguments as! [String: Any]
        let title = arguments[kTitleKey] as? String
        let base64Icon = arguments[kIconPathKey] as? String
        let toolTip = arguments[kToolTipKey] as? String
        let isTemplate = arguments[kIsTemplateKey] as? Bool
        let trayWidth = arguments[kTrayWidthKey] as? Float
        let isDual = arguments[kIsDualKey] as? Bool ?? false
        let upText = arguments[kUpTextKey] as? String
        let downText = arguments[kDownTextKey] as? String
      
        let maxAutoWidth =  Float(max(upText?.count ?? 0 , downText?.count ?? 0 ) * 9 + 5)
        
        if let trayWidth = trayWidth {
            statusItem?.length = CGFloat(trayWidth)
        }
        
        if let toolTip = toolTip {
            statusItem?.button?.toolTip = toolTip
        }
        
        if let trayWidth = trayWidth {
            statusItem?.length = CGFloat(trayWidth)
        }
        
        if(isDual){
            setDualTitle(base64Icon: base64Icon, upText: upText!, downText: downText!, width:  CGFloat( trayWidth ?? maxAutoWidth ), statusItem:statusItem)
        }else{
            statusItem?.button?.subviews.forEach { $0.removeFromSuperview() }
            if let title = title {
                statusItem?.button?.title = title
            }
            if let base64Icon = base64Icon {
                if let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters),
                   let itemImage = NSImage(data: imageData)
                {
                    let destSize = NSSize(width: kDefaultSizeWidth, height: kDefaultSizeHeight)
                    itemImage.size = destSize
                    itemImage.isTemplate = isTemplate ?? false
                    statusItem?.button?.image = itemImage
                    statusItem?.button?.imagePosition = NSControl.ImagePosition.imageLeft
                    
                }
            }
        }
        
        return result(true)
    }
    
    func setContextMenu(_ call: FlutterMethodCall, _ result: FlutterResult) {
        if let menuId = call.arguments as? Int {
            contextMenuId = menuId
        } else {
            contextMenuId = -1
        }
        result(true)
    }
    
    func popUpContextMenu(_ call: FlutterMethodCall, _ result: FlutterResult) {
        if let menu = menuManager?.getMenu(menuId: contextMenuId ?? -1) {
            let nsMenu = menu.getNSMenu()
            nsMenu?.delegate = self
            
            statusItem?.menu = nsMenu
            statusItem?.button?.performClick(nil)
            result(true)
            return
        }
        result(false)
    }
    
    func setPressedImage(_ call: FlutterMethodCall, _ result: FlutterResult) {
        let base64Icon = call.arguments as? String
        
        if let base64Icon = base64Icon {
            if let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters),
               let itemImage = NSImage(data: imageData)
            {
                let destSize = NSSize(width: kDefaultSizeWidth, height: kDefaultSizeHeight)
                itemImage.size = destSize
                statusItem?.button?.alternateImage = itemImage
                statusItem?.button?.setButtonType(.toggle)
            } else {
                statusItem?.button?.alternateImage = nil
            }
        } else {
            statusItem?.button?.alternateImage = nil
        }
        
        result(nil)
    }
    
    func getTitle(_ call: FlutterMethodCall, _ result: FlutterResult) {
        result(statusItem?.button?.title ?? "")
    }
    
    func destroySystemTray(_ call: FlutterMethodCall, _ result: FlutterResult) {
        contextMenuId = -1
        
        if statusItem != nil {
            NSStatusBar.system.removeStatusItem(statusItem!)
            
            statusItem?.button?.image = nil
            statusItem?.button?.alternateImage = nil
            statusItem = nil
        }
        result(true)
    }
}

class DualStatusItemView: NSView {
    var image: NSImage?
    var upText: String = ""
    var downText: String = ""
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let image = image {
            let imageSize = NSSize(width: dirtyRect.size.height-4, height: dirtyRect.size.height-4)
            let imageRect = NSRect(x: 5, y: 2, width: imageSize.width, height: imageSize.height)
            image.draw(in: imageRect)
        }
        
        if !upText.isEmpty {
            let upTextAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9),
                .foregroundColor: NSColor.textColor,
                .paragraphStyle: {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .right
                    paragraphStyle.lineHeightMultiple = 1.0
                    return paragraphStyle
                }()
            ]
            
            let upTextSize = (upText as NSString).size(withAttributes: upTextAttributes)
            let upTextRect = NSRect(x: dirtyRect.size.width - upTextSize.width - 5, y:  upTextSize.height, width: upTextSize.width, height: upTextSize.height)
            
            (upText as NSString).draw(in: upTextRect, withAttributes: upTextAttributes)
        }
        
        if !downText.isEmpty {
            let downTextAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9),
                .foregroundColor: NSColor.textColor,
                .paragraphStyle: {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .right
                    paragraphStyle.lineHeightMultiple = 1.0
                    return paragraphStyle
                }()
            ]
            
            let downTextSize = (downText as NSString).size(withAttributes: downTextAttributes)
            let downTextRect = NSRect(x: dirtyRect.size.width - downTextSize.width - 5, y: 1, width: downTextSize.width, height: downTextSize.height)
            
            (downText as NSString).draw(in: downTextRect, withAttributes: downTextAttributes)
        }
    }
}
