//
//  NewsWebView.swift
//  CSAI1
//
//  Created by DM on 3/16/25.
//


//
//  NewsWebView.swift
//  CRYPTOSAI
//
//  Displays a news article via WKWebView.
//

import SwiftUI
import WebKit

struct NewsWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        uiView.load(URLRequest(url: url))
    }
}
