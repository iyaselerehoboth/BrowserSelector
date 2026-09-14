//
//  main.swift
//  LinkRouter
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import Foundation

let app = LinkRouterApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.accessory)

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
