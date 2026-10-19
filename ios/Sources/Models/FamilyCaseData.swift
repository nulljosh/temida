import SwiftUI

// MARK: - CASE-0002
//
// Content is fetched at runtime from the Supabase `brief_data` table (key='cases',
// FAMILY_* keys) — see Store.loadCaseData() and CaseDataMapper.swift. No hardcoded
// case content lives in source.

@MainActor var familyCaseFacts: [CaseFact] = []
@MainActor var familyCaseGrounds: [Ground] = []
@MainActor var familyCaseWitnesses: [Witness] = []
@MainActor var familyCaseLawyers: [Lawyer] = []
@MainActor var familyCaseTimeline: [TimelineStep] = []
@MainActor var familyCaseChecklist: [ChecklistItem] = []
@MainActor var familyCaseScenarios: [Scenario] = []
@MainActor var familyDamageHeads: [DamageHead] = []
@MainActor var familyCallScript: String = ""
@MainActor var familyOutreachEmail: String = ""
