//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import AlertToast
import SwiftUI

struct ContentView: View {
  // MARK: - Properties
  @StateObject var viewModel: ContentViewModel
  @FocusState private var isFocused
  
  // MARK: - Body
  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        inputSection(geometry)
        if !viewModel.state.isTranslating {
          usageStatusBar
        }
        responseSection(geometry)
      }
      .ignoresSafeArea(edges: .bottom)
      .background(Color.background)
      .onTapGesture { isFocused = false }
      .onAppear {
        viewModel.send(.fetchAppInfo)
        viewModel.send(.fetchUserInfo)
        viewModel.send(.binding)
      }
      .toasts(viewModel: viewModel)
    }
  }
  
  // MARK: - Input Section
  private func inputSection(_ geometry: GeometryProxy) -> some View {
    Rectangle()
      .fill(Color.clear)
      .frame(
        maxHeight: viewModel.state.isTranslating
        ? geometry.size.height / 4
        : .infinity
      )
      .overlay {
        TextEditorView(
          text: Binding(
            get: { viewModel.state.beforeText },
            set: { viewModel.updateBeforeText($0) }
          ),
          isFocused: _isFocused,
          isDisabled: viewModel.state.isTranslating,
          onTextLengthExceeded: {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            viewModel.updateToast(\.textLengthExceeded, value: true)
          }
        )
      }
  }
  
  // MARK: - Usage Status Bar
  private var usageStatusBar: some View {
    HStack {
      Spacer()
      Text(
        "오늘 사용 가능한 횟수 \(viewModel.state.usedUsageCounts)/\(viewModel.state.totalUsageCounts)"
      )
      .nanumsquareneo(weight: .regular, size: 12)
      .foregroundColor(.black.opacity(0.3))
      Spacer()
    }
    .overlay {
      if viewModel.state.deleteAccountButtonVisible {
        deleteAccountButton
      }
    }
    .padding(.bottom)
  }
  
  private var deleteAccountButton: some View {
    HStack {
      Spacer()
      Image(systemName: "person.slash")
        .foregroundColor(.black.opacity(0.5))
        .padding(.trailing, 10)
    }
    .onTapGesture {
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      viewModel.updateToast(\.removeAccountCheck, value: true)
    }
    .alert("계정 삭제", isPresented: Binding(
      get: { viewModel.state.toast.removeAccountCheck },
      set: { viewModel.updateToast(\.removeAccountCheck, value: $0) }
    )) {
      Button("삭제", role: .destructive) {
        viewModel.send(.removeAccount)
        viewModel.updateToast(\.removeAccountSuccess, value: true)
      }
      Button("취소", role: .cancel) {}
    } message: {
      Text("정말로 계정을 삭제하시겠습니까?\n계정을 삭제해도 사용 횟수는 초기화되지 않습니다.")
    }
  }
  
  // MARK: - Response Section
  private func responseSection(_ geometry: GeometryProxy) -> some View {
    Rectangle()
      .fill(Color.accentColor)
      .frame(
        maxWidth: .infinity,
        maxHeight: viewModel.state.isTranslating
        ? .infinity
        : geometry.size.height / 4
      )
      .animation(
        .linear,
        value: viewModel.state.isTranslating
      )
      .overlay {
        VStack(spacing: 0) {
          Spacer()
          
          if viewModel.state.isTranslating {
            responseContentView(geometry)
            Spacer()
          }
          
          translateButton
          
          Spacer()
        }
      }
  }
  
  private func responseContentView(_ geometry: GeometryProxy) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        responseTextView()
          .frame(maxWidth: .infinity, alignment: .leading)
        
        if !viewModel.state.isGenerating {
          responseActions
            .padding(.top, 10)
        }
      }
    }
    .frame(
      width: geometry.size.width - 100,
      height: geometry.size.height / 2
    )
  }
  
  private func responseTextView() -> some View {
    Text(viewModel.state.responseText)
      .foregroundColor(.white)
      .nanumsquareneo(weight: .bold, size: 26)
      .lineSpacing(5)
  }
  
  private var responseActions: some View {
    HStack(spacing: 15) {
      Spacer()
      copyButton
      shareButton
    }
    .padding(.top, 10)
  }
  
  private var copyButton: some View {
    Image(systemName: "clipboard")
      .foregroundColor(.white)
      .onTapGesture {
        UIPasteboard.general.string = viewModel.state.responseText
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.updateToast(\.textCopied, value: true)
      }
  }
  
  private var shareButton: some View {
    ShareLink(item: viewModel.state.responseText) {
      Image(systemName: "square.and.arrow.up")
        .foregroundColor(.white)
    }
    .simultaneousGesture(TapGesture().onEnded {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      viewModel.updateToast(\.textShared, value: true)
    })
  }
  
  // MARK: - Translate Button
  private var translateButton: some View {
    VStack {
      Image(.luckyvicky)
        .resizable()
        .scaledToFit()
        .blendMode(.screen)
        .frame(width: 50)
        .rotationEffect(.degrees(viewModel.state.buttonRotation))
      
      Text(viewModel.state.isTranslating ? "돌아가기" : "변환하기")
        .foregroundColor(.white)
        .nanumsquareneo(weight: .bold, size: 16)
    }
    .onTapGesture {
      viewModel.send(.translate)
    }
    .disabled(viewModel.state.isGenerating)
  }
}

// MARK: - TextEditorView
struct TextEditorView: View {
  @Binding var text: String
  @FocusState var isFocused: Bool
  let isDisabled: Bool
  let onTextLengthExceeded: () -> Void
  
  var body: some View {
    VStack {
      TextField(
        "럭키비키하게 바꿔봐🍀",
        text: $text,
        axis: .vertical
      )
      .onChange(of: text) { newValue in
        if newValue.count > 45 {
          text = String(newValue.prefix(45))
          onTextLengthExceeded()
        }
      }
      .frame(height: 200)
      .foregroundColor(.black.opacity(0.7))
      .focused($isFocused)
      .nanumsquareneo(weight: .regular, size: 24)
      .lineSpacing(5)
      .multilineTextAlignment(.center)
      .submitLabel(.send)
      .padding(70)
      .disabled(isDisabled)
    }
  }
}

// MARK: - Toasts Extension
private extension View {
  func toasts(viewModel: ContentViewModel) -> some View {
    self
      .toast(isPresenting: Binding(
        get: { viewModel.state.error != nil },
        set: { _ in }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("exclamationmark.circle.fill", Color.red),
          title: viewModel.state.error?.localizedDescription
          ?? "에러가 발생했습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.textLengthExceeded },
        set: { viewModel.updateToast(\.textLengthExceeded, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("exclamationmark.circle.fill", Color.red),
          title: "글자 수 제한을 초과했습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.textEmpty },
        set: { viewModel.updateToast(\.textEmpty, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("exclamationmark.triangle.fill", Color.yellow),
          title: "텍스트를 입력해주세요"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.textCopied },
        set: { viewModel.updateToast(\.textCopied, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("checkmark.circle.fill", Color.green),
          title: "클립보드에 복사했습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.textShared },
        set: { viewModel.updateToast(\.textShared, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("checkmark.circle.fill", Color.green),
          title: "공유에 성공했습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.userInfoFetchSuccessed },
        set: { viewModel.updateToast(\.userInfoFetchSuccessed, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("checkmark.circle.fill", Color.green),
          title: "로그인에 성공했습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.usageExceeded },
        set: { viewModel.updateToast(\.usageExceeded, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("exclamationmark.circle.fill", Color.red),
          title: "하루 사용 횟수가 초과되었습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.usageAdded },
        set: { viewModel.updateToast(\.usageAdded, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("arrow.counterclockwise.circle.fill", .accentColor),
          title: "오늘 남은 사용 횟수는 \(viewModel.state.totalUsageCounts - viewModel.state.usedUsageCounts)번입니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.usageReseted },
        set: { viewModel.updateToast(\.usageReseted, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("plus.circle.fill", .blue),
          title: "사용 횟수가 초기화되었습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.removeAccountSuccess },
        set: { viewModel.updateToast(\.removeAccountSuccess, value: $0) }
      ), offsetY: 10) {
        AlertToast(
          displayMode: .hud,
          type: .systemImage("checkmark.circle.fill", .green),
          title: "계정이 성공적으로 삭제되었습니다"
        )
      }
      .toast(isPresenting: Binding(
        get: { viewModel.state.toast.isLoading },
        set: { viewModel.updateToast(\.isLoading, value: $0) }
      )) {
        AlertToast(type: .loading)
      }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(
      viewModel:
        DependencyContainer
        .shared
        .makeMockContainer()
        .makeContentViewModel()
    )
  }
}
