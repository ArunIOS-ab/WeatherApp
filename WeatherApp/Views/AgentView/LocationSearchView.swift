//
//  LocationSearchView.swift
//  WeatherApp
//
//  Search-as-you-type over the weatherapi.com geocoding endpoint. Selecting a
//  result makes it the active location, which re-scopes every insight and every
//  agent answer to that place.
//

import SwiftUI

struct LocationSearchView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField

                if let error = viewModel.searchError {
                    Text(error)
                        .font(FontScheme.kAvenirBook(size: getRelativeHeight(13.0)))
                        .foregroundColor(ColorConstants.Red400)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, getRelativeWidth(15.0))
                        .padding(.top, getRelativeHeight(12.0))
                }

                results
            }
            .background(ColorConstants.WhiteA700)
            .navigationTitle(StringConstants.kLblChangeLocation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(StringConstants.kLblClear) {
                        viewModel.clearSearch()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image("img_vector_bluegray_900")
                            .resizable()
                            .frame(width: getRelativeWidth(18.0), height: getRelativeHeight(14.0))
                            .scaledToFit()
                    }
                }
            }
        }
        .onAppear {
            // Prefill with the active city so the user can edit it directly
            // rather than starting from an empty field.
            if viewModel.searchQuery.isEmpty {
                viewModel.searchQuery = viewModel.location.name
            }
            isFieldFocused = true
        }
    }

    // MARK: Field

    private var searchField: some View {
        HStack(spacing: getRelativeWidth(8.0)) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: getRelativeHeight(14.0)))
                .foregroundColor(ColorConstants.Gray400)

            TextField(StringConstants.kLblSearchPlaceholder, text: $viewModel.searchQuery)
                .font(FontScheme.kAvenirRoman(size: getRelativeHeight(15.0)))
                .foregroundColor(ColorConstants.Black900)
                .focused($isFieldFocused)
                .submitLabel(.search)
                // Debounced inside the view model so every keystroke does not
                // become a request.
                .onChange(of: viewModel.searchQuery) { _ in
                    viewModel.searchLocations()
                }
                .autocorrectionDisabled()

            if viewModel.isSearching {
                ProgressView().scaleEffect(0.6)
            } else if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: getRelativeHeight(14.0)))
                        .foregroundColor(ColorConstants.Gray400)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(getRelativeWidth(12.0))
        .background(
            RoundedCorners(topLeft: 8.0, topRight: 8.0, bottomLeft: 8.0, bottomRight: 8.0)
                .fill(ColorConstants.Gray100)
        )
        .padding(.horizontal, getRelativeWidth(15.0))
        .padding(.top, getRelativeHeight(10.0))
    }

    // MARK: Results

    @ViewBuilder
    private var results: some View {
        if viewModel.searchResults.isEmpty {
            Spacer()
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.searchResults) { place in
                        Button {
                            Task {
                                await viewModel.select(location: place)
                                dismiss()
                            }
                        } label: {
                            row(for: place)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .background(ColorConstants.Gray200)
                            .padding(.leading, getRelativeWidth(15.0))
                    }
                }
            }
        }
    }

    private func row(for place: GeoLocation) -> some View {
        let isCurrent = place.id == viewModel.location.id

        return HStack(spacing: getRelativeWidth(10.0)) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: getRelativeHeight(14.0)))
                .foregroundColor(isCurrent ? ColorConstants.IndigoA400 : ColorConstants.Bluegray400)

            VStack(alignment: .leading, spacing: getRelativeHeight(2.0)) {
                Text(place.name)
                    .font(FontScheme.kAvenirRoman(size: getRelativeHeight(15.0)))
                    .foregroundColor(ColorConstants.Black900)

                if !place.displayName.isEmpty {
                    Text(place.displayName)
                        .font(FontScheme.kAvenirLight(size: getRelativeHeight(12.0)))
                        .foregroundColor(ColorConstants.Bluegray400)
                }
            }

            Spacer()

            if isCurrent {
                Image(systemName: "checkmark")
                    .font(.system(size: getRelativeHeight(13.0), weight: .semibold))
                    .foregroundColor(ColorConstants.IndigoA400)
            }
        }
        .padding(.horizontal, getRelativeWidth(15.0))
        .padding(.vertical, getRelativeHeight(12.0))
        .contentShape(Rectangle())
    }
}

struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(
            viewModel: WeatherViewModel(
                location: GeoLocation(name: "Ottawa", region: "Ontario",
                                      country: "Canada", lat: 45.42, lon: -75.7)
            )
        )
    }
}