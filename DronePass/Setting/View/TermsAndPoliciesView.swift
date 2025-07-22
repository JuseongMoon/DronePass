//
//  TermsAndPoliciesView.swift
//  DronePass
//
//  Created by 문주성 on 7/8/25.
//

import SwiftUI

struct TermsAndPoliciesView: View {
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLocationTerms = false

    var body: some View {
        List {
            Section {
                Button {
                    showTerms = true
                } label: {
                    HStack {
                        Text("이용약관")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                Button {
                    showPrivacy = true
                } label: {
                    HStack {
                        Text("개인정보 취급방침")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                Button {
                    showLocationTerms = true
                } label: {
                    HStack {
                        Text("위치기반 서비스 이용약관")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showLocationTerms) {
            LocationTermsView()
        }
    }
}

#Preview {
    TermsAndPoliciesView()
}
