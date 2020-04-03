//
//  Created by Tapash Majumder on 3/19/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK;

@objc(ReactIterableAPI)
class ReactIterableAPI: RCTEventEmitter {
    @objc static override func moduleName() -> String! {
        return "RNIterableAPI"
    }
    
    override var methodQueue: DispatchQueue! {
        _methodQueue
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        false
    }
    
    enum EventName: String, CaseIterable {
        case handleUrlCalled
        case handleCustomActionCalled
    }

    override func supportedEvents() -> [String]! {
        var result = [String]()
        EventName.allCases.forEach {
            result.append($0.rawValue)
        }
        return result
    }
    
    override func startObserving() {
        ITBInfo()
        shouldEmit = true
    }
    
    override func stopObserving() {
        ITBInfo()
        shouldEmit = false
    }
    
    @objc(initializeWithApiKey:config:)
    func initialize(apiKey: String, config configDict: [AnyHashable: Any]) {
        ITBInfo()
        let launchOptions = createLaunchOptions()
        let iterableConfig = ReactIterableAPI.createIterableConfig(from: configDict)
        if let urlDelegatePresent = configDict["urlDelegatePresent"] as? Bool, urlDelegatePresent == true {
            iterableConfig.urlDelegate = self
        }
        if let customActionDelegatePresent = configDict["customActionDelegatePresent"] as? Bool, customActionDelegatePresent == true {
            iterableConfig.customActionDelegate = self
        }
        
        DispatchQueue.main.async {
            IterableAPI.initialize(apiKey: apiKey, launchOptions: launchOptions, config: iterableConfig)
        }
    }

    @objc(setEmail:)
    func set(email: String?) {
        ITBInfo()
        IterableAPI.email = email
    }
    
    @objc(getEmail:rejecter:)
    func getEmail(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.email)
    }

    @objc(setUserId:)
    func set(userId: String?) {
        ITBInfo()
        IterableAPI.userId = userId
    }
    
    @objc(getUserId:rejecter:)
    func getUserId(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.userId)
    }
    
    @objc(setUrlHandled:)
    func set(urlHandled: Bool) {
        ITBInfo()
        self.urlHandled = urlHandled
        urlDelegateSemaphore.signal()
    }

    @objc(disableDeviceForCurrentUser)
    func disableDeviceForCurrentUser() {
        ITBInfo()
        IterableAPI.disableDeviceForCurrentUser()
    }
    
    @objc(disableDeviceForAllUsers)
    func disableDeviceForAllUsers() {
        ITBInfo()
        IterableAPI.disableDeviceForAllUsers()
    }

    @objc(getLastPushPayload:rejecter:)
    func getLastPushPayload(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.lastPushPayload)
    }

    @objc(getAttributionInfo:rejecter:)
    func getAttributionInfo(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        guard let attributionInfo = IterableAPI.attributionInfo else {
            resolver(NSNull())
            return
        }
        
        resolver(attributionInfo.toDictionary())
    }

    @objc(setAttributionInfo:)
    func set(attributionInfo dict: [AnyHashable: Any]?) {
        ITBInfo()
        guard let dict = dict else {
            IterableAPI.attributionInfo = nil
            return
        }

        IterableAPI.attributionInfo = dict.toDecodable()
    }
    
    @objc(trackPushOpenWithPayload:dataFields:)
    func trackPushOpen(payload: [AnyHashable: Any], dataFields: [AnyHashable: Any]?) {
        ITBInfo()
        IterableAPI.track(pushOpen: payload, dataFields: dataFields)
    }

    @objc(trackPushOpenWithCampaignId:templateId:messageId:appAlreadyRunning:dataFields:)
    func trackPushOpen(campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String?,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]?) {
        ITBInfo()
        IterableAPI.track(pushOpen: campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields)
    }
    
    @objc(trackPurchaseWithTotal:items:dataFields:)
    func trackPurchase(total: NSNumber,
                       items: [[AnyHashable: Any]],
                       dataFields: [AnyHashable: Any]?) {
        ITBInfo()
        IterableAPI.track(purchase: total,
                          items: items.compactMap(ReactIterableAPI.dictionaryToCommerceItem),
                          dataFields: dataFields)
    }

    @objc(getInAppMessages:rejecter:)
    func getInAppMessages(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.inAppManager.getMessages().map{ $0.toDictionary() })
    }
    
    @objc(trackEvent:)
    func track(event: String) {
        ITBInfo()
        IterableAPI.track(event: event)
    }
    
    private var shouldEmit = false
    private let _methodQueue = DispatchQueue(label: String(describing: ReactIterableAPI.self))
    
    // Handling url delegate
    private var urlHandled = false
    private var urlDelegateSemaphore = DispatchSemaphore(value: 0)
    
    private func createLaunchOptions() -> [UIApplication.LaunchOptionsKey: Any]? {
        guard let bridge = bridge else {
            return nil
        }

        return ReactIterableAPI.createLaunchOptions(bridgeLaunchOptions: bridge.launchOptions)
    }
    
    private static func createLaunchOptions(bridgeLaunchOptions: [AnyHashable: Any]?) -> [UIApplication.LaunchOptionsKey: Any]? {
        guard let bridgeLaunchOptions = bridgeLaunchOptions,
            let remoteNotification = bridgeLaunchOptions[UIApplication.LaunchOptionsKey.remoteNotification.rawValue] else {
            return nil
        }
        
        var result = [UIApplication.LaunchOptionsKey: Any]()
        result[UIApplication.LaunchOptionsKey.remoteNotification] = remoteNotification
        return result
    }
    
    private static func createIterableConfig(from dict: [AnyHashable: Any]?) -> IterableConfig {
        let config = IterableConfig()
        guard let dict = dict else {
            return config
        }
        
        if let pushIntegrationName = dict["pushIntegrationName"] as? String {
            config.pushIntegrationName = pushIntegrationName
        }
        if let sandboxPushIntegrationName = dict["sandboxPushIntegrationName"] as? String {
            config.sandboxPushIntegrationName = sandboxPushIntegrationName
        }
        if let intValue = dict["pushPlatform"] as? Int, let pushPlatform = PushServicePlatform(rawValue: intValue) {
            config.pushPlatform = pushPlatform
        }
        if let autoPushRegistration = dict["autoPushRegistration"] as? Bool {
            config.autoPushRegistration = autoPushRegistration
        }
        if let checkForDeferredDeeplink = dict["checkForDeferredDeeplink"] as? Bool {
            config.checkForDeferredDeeplink = checkForDeferredDeeplink
        }

        return config
    }

    
    // TODO: convert CommerceItem to Codable
    private static func dictionaryToCommerceItem(dict: [AnyHashable: Any]) -> CommerceItem? {
        guard let id = dict["id"] as? String else {
            return nil
        }
        guard let name = dict["name"] as? String else {
            return nil
        }
        guard let price = dict["price"] as? NSNumber else {
            return nil
        }
        guard let quantity = dict["quantity"] as? UInt else {
            return nil
        }

        return CommerceItem(id: id, name: name, price: price, quantity: quantity)
    }
    
    private static func inAppTriggerToDict(trigger: IterableInAppTrigger) -> [AnyHashable: Any] {
        var dict = [AnyHashable: Any]()
        dict["type"] = trigger.type.rawValue
        return dict
    }
    
    private static func edgeInsetsToDict(edgeInsets: UIEdgeInsets) -> [AnyHashable: Any] {
        var dict = [AnyHashable: Any]()
        dict["top"] = edgeInsets.top
        dict["left"] = edgeInsets.left
        dict["bottom"] = edgeInsets.bottom
        dict["right"] = edgeInsets.right
        return dict
    }
    
    private static func inAppMessageToDict(message: IterableInAppMessage) -> [AnyHashable: Any] {
        var dict = [AnyHashable: Any]()
        dict["messageId"] = message.messageId
        dict["campaignId"] = message.campaignId
        dict["trigger"] = inAppTriggerToDict(trigger: message.trigger)
        dict["createdAt"] = message.createdAt.map { $0.iterableIntValue }
        dict["expiresAt"] = message.expiresAt.map { $0.iterableIntValue }
//        dict["content"] =
        return dict
    }
}

extension ReactIterableAPI: IterableURLDelegate {
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        ITBInfo()

        guard shouldEmit == true else {
            return false
        }

        let contextDict = ReactIterableAPI.contextToDictionary(context: context)
        sendEvent(withName: EventName.handleUrlCalled.rawValue, body: ["url": url.absoluteString, "context": contextDict])

        let timeoutResult = urlDelegateSemaphore.wait(timeout: .now() + 2.0)
        if timeoutResult == .success {
            ITBInfo("urlHandled: \(urlHandled)")
            return urlHandled
        } else {
            ITBInfo("timed out")
            return false
        }
    }

    private static func contextToDictionary(context: IterableActionContext) -> [AnyHashable: Any] {
        var result = [AnyHashable: Any]()
        let actionDict = actionToDictionary(action: context.action)
        result["action"] = actionDict
        result["source"] = context.source.rawValue
        return result
    }
    
    private static func actionToDictionary(action: IterableAction) -> [AnyHashable: Any] {
        var actionDict = [AnyHashable: Any]()
        actionDict["type"] = action.type
        if let data = action.data {
            actionDict["data"] = data
        }
        if let userInput = action.userInput {
            actionDict["userInput"] = userInput
        }
        return actionDict
    }
}

extension ReactIterableAPI: IterableCustomActionDelegate {
    func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool {
        ITBInfo()
        let actionDict = ReactIterableAPI.actionToDictionary(action: action)
        let contextDict = ReactIterableAPI.contextToDictionary(context: context)
        sendEvent(withName: EventName.handleCustomActionCalled.rawValue, body: ["action": actionDict, "context": contextDict])
        return true
    }
}

// TODO: make public
extension Encodable {
    public func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
    }
}

// TODO: make public
extension Dictionary where Key == AnyHashable, Value == Any {
    public func toDecodable<T>() -> T? where T: Decodable {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)

    }
}

// TODO: make public
extension Date {
    public var iterableIntValue: Int {
        return Int(self.timeIntervalSince1970 * 1000)
    }
}

// TODO: make public
extension Int {
    public var iterableDateValue: Date {
        let seconds = Double(self) / 1000.0 // ms -> seconds
        
        return Date(timeIntervalSince1970: seconds)
    }
}
