import FlutterMacOS

private let kDefaultIconSizeWidth = 18
private let kDefaultIconSizeHeight = 18

private let kMenuIdKey = "menu_id"
private let kMenuItemIdKey = "menu_item_id"
private let kMenuListKey = "menu_list"
private let kIdKey = "id"
private let kTypeKey = "type"
private let kCheckboxKey = "checkbox"
private let kSeparatorKey = "separator"
private let kSubMenuKey = "submenu"
private let kLabelKey = "label"
private let kSubLabelKey = "sub_label"
private let kImageKey = "image"
private let kEnabledKey = "enabled"
private let kCheckedKey = "checked"
private let kSubLabelMaxLenghtKey = "sub_label_max_length"

private let kMenuItemSelectedCallbackMethod = "MenuItemSelectedCallback"

//https://stackoverflow.com/questions/26044110/searching-nsmenuitem-inside-nsmenu-recursively/70609223#70609223
extension NSMenu {
    func item(withTag tag: Int, recursive: Bool) -> NSMenuItem? {
        if !recursive {
            return item(withTag: tag)
        }
        for item in items {
            if item.tag == tag {
                return item
            } else if item.hasSubmenu {
                if let result = item.submenu!.item(withTag: tag, recursive: recursive) {
                    return result
                }
            }
        }
        return nil
    }
}

class Menu: NSObject {
    var channel: FlutterMethodChannel
    var menuId: Int
    var nsMenu: NSMenu?
    
    init(_ channel: FlutterMethodChannel, _ menuId: Int) {
        self.channel = channel
        self.menuId = menuId
    }
    
    func createContextMenu(_ call: FlutterMethodCall) -> Bool {
        var result = false
        
        repeat {
            let arguments = call.arguments as! [String: Any]
            let menuList = arguments[kMenuListKey] as? [[String: Any]]
            
            if menuList == nil {
                break
            }
            
            if !createContextMenu(menuList!) {
                break
            }
            
            result = true
        } while false
        
        return result
    }
    
    func setLabel(_ call: FlutterMethodCall, _ result: FlutterResult) {
        repeat {
            let arguments = call.arguments as! [String: Any]
            let menuItemId = arguments[kMenuItemIdKey] as? Int
            let label = arguments[kLabelKey] as? String
            
            if menuItemId == nil || label == nil {
                break
            }
            
            setLabel(menuItemId: menuItemId!, label: label!)
            
            result(true)
            return
        } while false
        
        result(false)
    }
    
    func setImage(_ call: FlutterMethodCall, _ result: FlutterResult) {
        repeat {
            let arguments = call.arguments as! [String: Any]
            let menuItemId = arguments[kMenuItemIdKey] as? Int
            let image = arguments[kImageKey] as? String
            
            if menuItemId == nil {
                break
            }
            
            setImage(menuItemId: menuItemId!, base64Icon: image)
            
            result(true)
            return
        } while false
        
        result(false)
    }
    
    func setEnable(_ call: FlutterMethodCall, _ result: FlutterResult) {
        repeat {
            let arguments = call.arguments as! [String: Any]
            let menuItemId = arguments[kMenuItemIdKey] as? Int
            let enabled = arguments[kEnabledKey] as? Bool
            
            if menuItemId == nil || enabled == nil {
                break
            }
            
            setEnable(menuItemId: menuItemId!, enabled: enabled!)
            
            result(true)
            return
        } while false
        
        result(false)
    }
    
    func setCheck(_ call: FlutterMethodCall, _ result: FlutterResult) {
        repeat {
            let arguments = call.arguments as! [String: Any]
            let menuItemId = arguments[kMenuItemIdKey] as? Int
            let checked = arguments[kCheckedKey] as? Bool
            
            if menuItemId == nil || checked == nil {
                break
            }
            
            setCheck(menuItemId: menuItemId!, checked: checked!)
            
            result(true)
            return
        } while false
        
        result(false)
    }
    
    func createContextMenu(_ items: [[String: Any]]) -> Bool {
        repeat {
            let nsMenu = NSMenu()
            if !valueToMenu(menu: nsMenu, items: items) {
                break
            }
            
            self.nsMenu = nsMenu
            return true
        } while false
        
        return false
    }
    
    func getNSMenu() -> NSMenu? {
        return nsMenu
    }
    
    func setLabel(menuItemId: Int, label: String) {
        self.nsMenu?.item(withTag: menuItemId, recursive: true)?.title = label
    }
    
    func setImage(menuItemId: Int, base64Icon: String?) {
        var image: NSImage?
        if let base64Icon = base64Icon {
            if let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters),
               let itemImage = NSImage(data: imageData)
            {
                itemImage.size = NSSize(width: kDefaultIconSizeWidth, height: kDefaultIconSizeHeight)
                image = itemImage
            }
        }
        
        self.nsMenu?.item(withTag: menuItemId, recursive: true)?.image = image
    }
    
    func setEnable(menuItemId: Int, enabled: Bool) {
        self.nsMenu?.item(withTag: menuItemId, recursive: true)?.isEnabled = enabled
    }
    
    func setCheck(menuItemId: Int, checked: Bool) {
        self.nsMenu?.item(withTag: menuItemId, recursive: true)?.state = checked ? .on : .off
    }
    
    func setAttributedTitle(menuItem: NSMenuItem, name: String, secondLabel: String?, maxLength: CGFloat = 0,chipLabel:String = "test", chipBackgroundColor:Int = 0xff66ccff,chipLabelColor:Int = 0xffffffff) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.tabStops = [
            NSTextTab(textAlignment: .right, location: maxLength + 64, options: [:])
        ]
        let name = name.replacingOccurrences(of: "\t", with: " ")
        
        let str: String
        if let label = secondLabel {
            var truncatedLabel: String = ""
            if label.count > 20 {
                let startIndex = label.index(label.endIndex, offsetBy: -20)
                let truncatedText = label[startIndex...]
                truncatedLabel = "...\(truncatedText)"
            } else {
                truncatedLabel = label
            }
            str = "\(name)\t\(truncatedLabel)"
        } else {
            str = name.appending(" ")
        }
        
        let attributed = NSMutableAttributedString(
            string: str,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraph,
                NSAttributedString.Key.font: NSFont.menuBarFont(ofSize: 14)
            ]
        )
        
        let hackAttr = [NSAttributedString.Key.font: NSFont.menuBarFont(ofSize: 15)]
        attributed.addAttributes(hackAttr, range: NSRange(name.utf16.count..<name.utf16.count + 1))
        
        if secondLabel != nil {
            let delayAttr = [
                NSAttributedString.Key.font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
                NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor
            ]
            attributed.addAttributes(delayAttr, range: NSRange(name.utf16.count + 1..<str.utf16.count))
        } 
        menuItem.attributedTitle = attributed
    }
    
    func valueToMenu(menu: NSMenu, items: [[String: Any]]) -> Bool {
        for item in items {
            if !valueToMenuItem(menu: menu, item: item) {
                return false
            }
        }
        return true
    }
    
    func valueToMenuItem(menu: NSMenu, item: [String: Any]) -> Bool {
        let type = item[kTypeKey] as? String
        if type == nil {
            return false
        }
        
        let label = item[kLabelKey] as? String ?? ""
        let subLabel:String? = item[kSubLabelKey] as? String
        let id = item[kIdKey] as? Int ?? -1
        let maxLength = item[kSubLabelMaxLenghtKey] as? Double ?? 0
        
        var image: NSImage?
        if let base64Icon = item[kImageKey] as? String {
            if let imageData = Data(base64Encoded: base64Icon, options: .ignoreUnknownCharacters),
               let itemImage = NSImage(data: imageData)
            {
                itemImage.size = NSSize(width: kDefaultIconSizeWidth, height: kDefaultIconSizeHeight)
                image = itemImage
            }
        }
        
        let isEnabled = item[kEnabledKey] as? Bool ?? false
        
        switch type! {
        case kSeparatorKey:
            menu.addItem(.separator())
        case kSubMenuKey:
            let subMenu = NSMenu()
            let children = item[kSubMenuKey] as? [[String: Any]] ?? [[String: Any]]()
            if valueToMenu(menu: subMenu, items: children) {
                let menuItem = NSMenuItem()
                // menuItem.title = label
                menuItem.image = image
                menuItem.submenu = subMenu
                menu.addItem(menuItem)
                setAttributedTitle(menuItem:menuItem,name: label, secondLabel: subLabel, maxLength: CGFloat(maxLength))
            }
        case kCheckboxKey:
            let isChecked = item[kCheckedKey] as? Bool ?? false
            
            let menuItem = NSMenuItem()
            // menuItem.title = label
            setAttributedTitle(menuItem:menuItem,name: label, secondLabel: subLabel, maxLength: CGFloat(maxLength))
            menuItem.image = image
            menuItem.target = self
            menuItem.action = isEnabled ? #selector(onMenuItemSelectedCallback) : nil
            menuItem.tag = id
            menuItem.state = isChecked ? .on : .off
            menu.addItem(menuItem)
        default:
            let menuItem = NSMenuItem()
            // menuItem.title = label
            setAttributedTitle(menuItem:menuItem,name: label, secondLabel: subLabel, maxLength: CGFloat(maxLength))
            menuItem.image = image
            menuItem.target = self
            menuItem.action = isEnabled ? #selector(onMenuItemSelectedCallback) : nil
            menuItem.tag = id
            menu.addItem(menuItem)
        }
        
        return true
    }
    
    @objc func onMenuItemSelectedCallback(_ sender: Any) {
        let menuItem = sender as! NSMenuItem
        channel.invokeMethod(
            kMenuItemSelectedCallbackMethod,
            arguments: [kMenuIdKey: menuId, kMenuItemIdKey: menuItem.tag],
            result: nil)
    }
}

extension CGColor {
    static func fromHexInt(_ hexInt: UInt32) -> CGColor? {
        let red = CGFloat((hexInt & 0xFF000000) >> 24) / 255.0
        let green = CGFloat((hexInt & 0x00FF0000) >> 16) / 255.0
        let blue = CGFloat((hexInt & 0x0000FF00) >> 8) / 255.0
        let alpha = CGFloat(hexInt & 0x000000FF) / 255.0
        
        let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
        return color.cgColor
    }
}

extension NSColor {
    convenience init?(hex: UInt32) {
        let red = CGFloat((hex & 0xFF000000) >> 24) / 255.0
        let green = CGFloat((hex & 0x00FF0000) >> 16) / 255.0
        let blue = CGFloat((hex & 0x0000FF00) >> 8) / 255.0
        let alpha = CGFloat(hex & 0x000000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}


class ChipView: NSView {
    var delay: String = "" {
        didSet {
            // 触发视图重新绘制
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制背景色
        NSColor.blue.setFill()
        dirtyRect.fill()
        
        // 绘制文字
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        
        let textSize = delay.size(withAttributes: attributes)
        let textRect = NSRect(
            x: bounds.midX - textSize.width / 2,
            y: bounds.midY - textSize.height / 2,
            width: min(textSize.width, bounds.width),
            height: min(textSize.height, bounds.height)
        )
        
        delay.draw(in: textRect, withAttributes: attributes)
    }
}
