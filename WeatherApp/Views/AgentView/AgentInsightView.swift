//
//  AgentInsightView.swift
//  WeatherApp
//
//  Dashboard component rendering proactive agent recommendations, plus the
//  conversational assistant surface.
//

import SwiftUI

// MARK: - Insight card

struct AgentInsightView: View {
    let insight: AgentInsight
    var onDismiss: (() -> Void)?
    /// Optional prompt chip that jumps straight into the chat with this insight.
    var onFollowUp: ((AgentInsight) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: getRelativeWidth(12.0)) {
            Image(systemName: insight.kind.symbolName)
                .resizable()
                .frame(width: getRelativeWidth(18.0), height: getRelativeWidth(18.0))
                .foregroundColor(Color(insight.kind.tint))
                .padding(.top, getRelativeHeight(2.0))

            VStack(alignment: .leading, spacing: getRelativeHeight(4.0)) {
                Text(insight.title)
                    .font(FontScheme.kAvenirHeavy(size: getRelativeHeight(14.0)))
                    .foregroundColor(ColorConstants.Black900)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text(insight.detail)
                    .font(FontScheme.kAvenirBook(size: getRelativeHeight(13.0)))
                    .foregroundColor(ColorConstants.Bluegray700)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                if let onFollowUp = onFollowUp {
                    Button {
                        onFollowUp(insight)
                    } label: {
                        Text(StringConstants.kLblAskAgent)
                            .font(FontScheme.kAvenirMedium(size: getRelativeHeight(12.0)))
                            .foregroundColor(ColorConstants.IndigoA400)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, getRelativeHeight(2.0))
                }
            }

            Spacer(minLength: 0)

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image("img_vector_gray_400")
                        .resizable()
                        .frame(width: getRelativeWidth(14.0), height: getRelativeWidth(14.0))
                        .scaledToFit()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(getRelativeWidth(14.0))
        .background(
            RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0, bottomRight: 8.0)
                .fill(ColorConstants.Gray101)
        )
    }
}

// MARK: - Insight stack

/// The list of proactive insights on the dashboard. Horizontal paging keeps it
/// compact above the forecast sections.
struct AgentInsightsSection: View {
    let insights: [AgentInsight]
    var onAsk: ((AgentInsight) -> Void)?

    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: getRelativeHeight(10.0)) {
                HStack(spacing: getRelativeWidth(6.0)) {
                    Image("img_vector_bluegray_700")
                        .resizable()
                        .frame(width: getRelativeWidth(15.0), height: getRelativeHeight(13.0))
                        .scaledToFit()
                    Text(StringConstants.kLblAgentRecommendations)
                        .font(FontScheme.kAvenirHeavy(size: getRelativeHeight(12.0)))
                        .foregroundColor(ColorConstants.Bluegray700)
                    Spacer()
                    Text(StringConstants.kLblLive)
                        .font(FontScheme.kAvenirMedium(size: getRelativeHeight(10.0)))
                        .foregroundColor(ColorConstants.IndigoA400)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: getRelativeWidth(10.0)) {
                        ForEach(insights) { insight in
                            AgentInsightView(insight: insight, onFollowUp: onAsk)
                                .frame(width: getRelativeWidth(280.0))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Chat bubble

struct AgentMessageBubble: View {
    let message: AgentMessage
    @State private var showReasoning = false

    private var isUser: Bool {
        message.role == .user
    }

    private var isToolCall: Bool {
        if case .toolCall = message.role { return true }
        return false
    }

    var body: some View {
        if isToolCall {
            toolCallBubble
        } else {
            chatBubble
        }
    }

    // MARK: Chat

    private var chatBubble: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isUser { Spacer(minLength: getRelativeWidth(40.0)) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: getRelativeHeight(6.0)) {
                if !isUser, let reasoning = message.reasoning, !reasoning.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showReasoning = !showReasoning
                        }
                    } label: {
                        HStack(spacing: getRelativeWidth(4.0)) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: getRelativeHeight(10.0)))
                            Text(showReasoning ? StringConstants.kLblHideThinking
                                               : StringConstants.kLblThinking)
                        }
                        .font(FontScheme.kAvenirMedium(size: getRelativeHeight(11.0)))
                        .foregroundColor(ColorConstants.Bluegray400)
                    }
                    .buttonStyle(.plain)

                    if showReasoning {
                        Text(reasoning)
                            .font(FontScheme.kAvenirLight(size: getRelativeHeight(11.0)))
                            .foregroundColor(ColorConstants.Bluegray400)
                            .padding(getRelativeWidth(8.0))
                            .background(
                                RoundedCorners(topLeft: 6.0, topRight: 6.0,
                                               bottomLeft: 6.0, bottomRight: 6.0)
                                    .fill(ColorConstants.Gray100)
                            )
                    }
                }

                if message.isPending {
                    TypingIndicator()
                        .padding(.vertical, getRelativeHeight(4.0))
                } else {
                    // AttributedString renders inline markdown, so the model
                    // can bold values without us writing manual parsing.
                    Text(attributedText)
                        .font(FontScheme.kAvenirBook(size: getRelativeHeight(14.0)))
                        .foregroundColor(isUser ? ColorConstants.WhiteA700 : ColorConstants.Black900)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(getRelativeWidth(12.0))
            .padding(.vertical, getRelativeHeight(10.0))
            .background(
                RoundedCorners(topLeft: 14.0, topRight: 14.0, bottomLeft: 14.0, bottomRight: 14.0)
                    .fill(isUser ? ColorConstants.IndigoA400 : ColorConstants.Gray101)
            )

            if !isUser { Spacer(minLength: getRelativeWidth(40.0)) }
        }
    }

    private var attributedText: AttributedString {
        (try? AttributedString(markdown: message.text)) ?? AttributedString(message.text)
    }

    // MARK: Tool call

    /// Collapsed by default. Tool chatter should be inspectable, not dominant.
    private var toolCallBubble: some View {
        let detail = toolDetail

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showReasoning = !showReasoning
                }
            } label: {
                HStack(spacing: getRelativeWidth(6.0)) {
                    Image(systemName: showReasoning ? "chevron.down" : "chevron.right")
                        .font(.system(size: getRelativeHeight(9.0)))
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: getRelativeHeight(10.0)))
                    Text(toolName)
                        .font(FontScheme.kAvenirMedium(size: getRelativeHeight(11.0)))
                    Spacer()
                    Image(systemName: detail.contains("failed") ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: getRelativeHeight(10.0)))
                        .foregroundColor(detail.contains("failed")
                                         ? ColorConstants.Red400
                                         : ColorConstants.Bluegray400)
                }
                .font(FontScheme.kAvenirMedium(size: getRelativeHeight(11.0)))
                .foregroundColor(ColorConstants.Bluegray700)
            }
            .buttonStyle(.plain)

            if showReasoning {
                Text(detail)
                    .font(FontScheme.kAvenirLight(size: getRelativeHeight(11.0)))
                    .foregroundColor(ColorConstants.Bluegray700)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, getRelativeHeight(6.0))
            }
        }
        .padding(getRelativeWidth(10.0))
        .background(
            RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0, bottomRight: 8.0)
                .fill(ColorConstants.Gray102)
        )
    }

    private var toolName: String {
        if case .toolCall(let name, _) = message.role { return name }
        return "tool"
    }

    private var toolDetail: String {
        if case .toolCall(_, let detail) = message.role { return detail }
        return ""
    }
}

// MARK: - Typing indicator

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: getRelativeWidth(4.0)) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(ColorConstants.Bluegray400)
                    .frame(width: getRelativeWidth(6.0), height: getRelativeWidth(6.0))
                    .opacity(phase > Double(index) * 0.5 ? 1.0 : 0.3)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 3.0
            }
        }
    }
}

// MARK: - Chat sheet

struct AgentChatView: View {
    @ObservedObject var viewModel: WeatherViewModel
    /// Prefilled question, set when the user taps an insight card. Sent once
    /// on appear, then ignored on subsequent presentations.
    var initialQuestion: String? = nil
    @State private var draft: String = ""
    @State private var didSendInitialQuestion = false
    @FocusState private var isInputFocused: Bool

    /// Suggested prompts, seeded from current conditions so they are relevant.
    private var suggestions: [String] {
        let city = viewModel.location.name
        return [
            "Is it a good day to run outdoors?",
            "What should I pack for a weekend in \(city)?",
            "When should I go for a walk?",
            "What should I wear today?"
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: getRelativeHeight(12.0)) {
                        if viewModel.messages.isEmpty {
                            emptyState
                        }

                        ForEach(viewModel.messages) { message in
                            AgentMessageBubble(message: message)
                                .id(message.id)
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, getRelativeWidth(14.0))
                    .padding(.vertical, getRelativeHeight(14.0))
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            inputBar
        }
        .background(ColorConstants.WhiteA700)
        .onAppear {
            // Fire the follow-up exactly once per presentation so dismissing
            // and reopening the sheet does not re-ask.
            guard !didSendInitialQuestion,
                  let question = initialQuestion,
                  !question.isEmpty
            else { return }
            didSendInitialQuestion = true
            send(question)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: getRelativeHeight(2.0)) {
                Text(StringConstants.kLblWeatherAgent)
                    .font(FontScheme.kAvenirHeavy(size: getRelativeHeight(18.0)))
                    .foregroundColor(ColorConstants.Black900)
                Text(viewModel.location.fullName)
                    .font(FontScheme.kAvenirLight(size: getRelativeHeight(12.0)))
                    .foregroundColor(ColorConstants.Bluegray400)
            }

            Spacer()

            Button {
                Task { await viewModel.clearConversation() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: getRelativeHeight(15.0)))
                    .foregroundColor(ColorConstants.Bluegray700)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, getRelativeWidth(14.0))
        .padding(.vertical, getRelativeHeight(12.0))
        .overlay(
            Divider().background(ColorConstants.Gray200),
            alignment: .bottom
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: getRelativeHeight(14.0)) {
            Text(StringConstants.kMsgAgentIntro)
                .font(FontScheme.kAvenirBook(size: getRelativeHeight(14.0)))
                .foregroundColor(ColorConstants.Bluegray700)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: getRelativeHeight(8.0)) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        send(suggestion)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: getRelativeHeight(11.0)))
                            Text(suggestion)
                                .font(FontScheme.kAvenirBook(size: getRelativeHeight(13.0)))
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .foregroundColor(ColorConstants.IndigoA400)
                        .padding(getRelativeWidth(10.0))
                        .background(
                            RoundedCorners(topLeft: 8.0, topRight: 8.0,
                                           bottomLeft: 8.0, bottomRight: 8.0)
                                .fill(ColorConstants.Gray101)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, getRelativeHeight(8.0))
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: getRelativeWidth(8.0)) {
            TextField(placeholder, text: $draft, axis: .vertical)
                .font(FontScheme.kAvenirBook(size: getRelativeHeight(14.0)))
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(getRelativeWidth(10.0))
                .background(
                    RoundedCorners(topLeft: 18.0, topRight: 18.0,
                                   bottomLeft: 18.0, bottomRight: 18.0)
                        .fill(ColorConstants.Gray101)
                )
                // Submitting via the return key is expected in a chat surface.
                .onSubmit { send(draft) }

            Button {
                send(draft)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: getRelativeHeight(15.0), weight: .semibold))
                    .foregroundColor(ColorConstants.WhiteA700)
                    .frame(width: getRelativeWidth(36.0), height: getRelativeWidth(36.0))
                    .background(Circle().fill(canSend ? ColorConstants.IndigoA400 : ColorConstants.Gray400))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, getRelativeWidth(14.0))
        .padding(.vertical, getRelativeHeight(10.0))
        .overlay(Divider().background(ColorConstants.Gray200), alignment: .top)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isAgentThinking
            && viewModel.canAskAgent
    }

    /// Placeholder that tells the user why input is unavailable, instead of a
    /// send button that silently does nothing.
    private var placeholder: String {
        viewModel.canAskAgent
            ? StringConstants.kMsgAskAgentPlaceholder
            : StringConstants.kMsgWaitingForWeather
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft = ""
        isInputFocused = false
        Task { await viewModel.ask(trimmed) }
    }
}