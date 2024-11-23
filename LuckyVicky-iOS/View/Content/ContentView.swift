//
//  ContentView.swift
//  LuckyVicky
//
//  Created by namdghyun on 7/6/24.
//

import AlertToast
import SwiftUI

struct ContentView: View {
  @StateObject var viewModel: ContentViewModel
  @FocusState private var isFocused
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        mainContent(geometry)
          .ignoresSafeArea(edges: .bottom)
      }
      .onTapGesture { isFocused = false }
      .onAppear {
        viewModel.send(.fetchAppInfo)
        viewModel.send(.fetchUserInfo)
        viewModel.send(.binding)
      }
      .toasts(viewModel: viewModel)
    }
  }
  
  // MARK: - Main Content
  private func mainContent(_ geometry: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      Spacer(minLength: 0)
      
      inputArea(geometry)
      
      Spacer(minLength: 0)
      
      if !viewModel.state.isTranslating {
        usageStatusBar
      }
      
      Spacer(minLength: 0)
      
      responseArea(geometry)
    }
  }
  
  // MARK: - Input Area
  private func inputArea(_ geometry: GeometryProxy) -> some View {
    let inputHeight = viewModel.state.isTranslating
    ? geometry.size.height * 0.25
    : geometry.size.height * 0.75
    
    return VStack {
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
        }, onToolbarButtonTapped: {
          viewModel.send(.translate)
        }
      )
    }
    .frame(height: inputHeight)
    .animation(.spring(), value: viewModel.state.isTranslating)
  }
  
  // MARK: - Usage Status Bar
  private var usageStatusBar: some View {
    HStack {
      Text("오늘 사용 가능한 횟수 \(viewModel.state.usedUsageCounts)/\(viewModel.state.totalUsageCounts)")
        .nanumsquareneo(weight: .regular, size: 12)
        .foregroundColor(.black.opacity(0.3))
      
      Spacer()
      
      if viewModel.state.deleteAccountButtonVisible {
        deleteAccountButton
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
  
  // MARK: - Delete Account Button
  private var deleteAccountButton: some View {
    Image(systemName: "person.slash")
      .foregroundColor(.black.opacity(0.5))
      .padding(.trailing, 10)
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
    } message: {
      Text("정말로 계정을 삭제하시겠습니까?")
    }
  }
  
  // MARK: - Response Area
  private func responseArea(_ geometry: GeometryProxy) -> some View {
    let responseHeight = viewModel.state.isTranslating
    ? geometry.size.height * 0.75
    : geometry.size.height * 0.25
    
    return VStack(spacing: 0) {
      Rectangle()
        .fill(Color.accentColor)
        .frame(height: responseHeight)
        .animation(.spring(), value: viewModel.state.isTranslating)
        .overlay {
          VStack {
            if viewModel.state.isTranslating {
              ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                  responseTextView()
                  
                  if !viewModel.state.isGenerating {
                    responseActions
                  }
                }
                .padding(.horizontal, 54)
                .padding(.vertical, 48)
              }
            }
            
            Spacer()
            
            translateButton
              .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
          }
        }
    }
  }
  
  // MARK: - Response Components
  private func responseTextView() -> some View {
    Text(viewModel.state.responseText)
      .foregroundColor(.white)
      .nanumsquareneo(weight: .bold, size: 26)
      .lineSpacing(5)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var responseActions: some View {
    HStack {
      Spacer()
      
      copyButton
        .padding(.trailing, 15)
      
      shareButton
    }
  }
  
  // MARK: - Action Buttons
  private var translateButton: some View {
    VStack(spacing: 8) {
      Image(.luckyvicky)
        .resizable()
        .scaledToFit()
        .frame(width: 50, height: 50)
        .blendMode(.screen)
        .rotationEffect(.degrees(viewModel.state.buttonRotation))
      
      Text(viewModel.state.isTranslating ? "돌아가기" : "변환하기")
        .foregroundColor(.white)
        .nanumsquareneo(weight: .bold, size: 16)
    }
    .disabled(viewModel.state.isGenerating)
    .onTapGesture {
      withAnimation(.spring()) {
        viewModel.send(.translate)
      }
    }
  }
  
  private var copyButton: some View {
    Button {
      UIPasteboard.general.string = viewModel.state.responseText
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      viewModel.updateToast(\.textCopied, value: true)
    } label: {
      Image(systemName: "clipboard")
        .foregroundColor(.white)
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
}

// MARK: - TextEditorView
fileprivate struct TextEditorView: View {
  @Binding var text: String
  @FocusState var isFocused: Bool
  let isDisabled: Bool
  let onTextLengthExceeded: () -> Void
  let onToolbarButtonTapped: () -> Void
  
  var body: some View {
    VStack {
      TextField("럭키비키하게 바꿔봐", text: $text, axis: .vertical)
        .onChange(of: text) { newValue in
          if newValue.count > 45 {
            text = String(newValue.prefix(45))
            onTextLengthExceeded()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .foregroundColor(.black.opacity(0.7))
        .focused($isFocused)
        .nanumsquareneo(weight: .regular, size: 24)
        .lineSpacing(5)
        .multilineTextAlignment(.center)
        .submitLabel(.return)
        .disabled(isDisabled)
        .toolbar {
          ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(action: {
              isFocused = false
              onToolbarButtonTapped()
            }) {
              HStack(alignment: .center) {
                Image(.luckyvicky)
                  .resizable()
                  .frame(width: 14, height: 14)
                  .blendMode(.screen)
                
                Text("변환하기")
                  .nanumsquareneo(weight: .bold, size: 14)
                  .foregroundColor(.white)
              }
              .padding(5)
              .background(.accent)
              .clipShape(RoundedRectangle(cornerRadius: 5))
            }
          }
        }
    }
    .background(Color.white)
  }
}

// MARK: - Toasts Extension
fileprivate extension View {
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

#if DEBUG
#Preview {
  ContentView(
    viewModel:
      DependencyContainer
      .shared
      .makeMockContainer()
      .makeContentViewModel()
  )
}
#endif
