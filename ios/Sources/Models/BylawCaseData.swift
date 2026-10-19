import SwiftUI

// MARK: - CASE-0004: City of Vancouver bylaw notice dispute
//
// Content is fetched at runtime from the Supabase `brief_data` table (key='cases',
// BYLAW_* keys) — see Store.loadCaseData() and CaseDataMapper.swift. No hardcoded
// case content lives in source.

@MainActor var bylawCaseFacts: [CaseFact] = []
@MainActor var bylawCaseGrounds: [Ground] = []
@MainActor var bylawCaseWitnesses: [Witness] = []
@MainActor var bylawCaseLawyers: [Lawyer] = []
@MainActor var bylawCaseTimeline: [TimelineStep] = []
@MainActor var bylawCaseChecklist: [ChecklistItem] = []
@MainActor var bylawCaseScenarios: [Scenario] = []
@MainActor var bylawDamageHeads: [DamageHead] = []
@MainActor var bylawCallScript: String = ""
