import Foundation

// MARK: - Initial persisted state (centralized; JSON-only, backward compatible)
//
// User-facing creation uses `.smartCanvas` and `.blankBoard` only. Other cases stay for decode + older boards.

extension FlowDeskBoardTemplate {
    /// Full board snapshot for a new document from this template.
    func makeInitialCanvasState() -> CanvasBoardState {
        var state = CanvasBoardState()
        state.boardTemplate = self
        state.viewport = Self.viewport(for: self)
        state.elements = Self.elements(for: self)
        return state
    }

    /// Tool to activate when the editor opens this board. Session-only UI state lives in the view model, not JSON.
    var preferredInitialCanvasTool: CanvasToolMode {
        .select
    }

    private static func viewport(for template: FlowDeskBoardTemplate) -> ViewportState {
        switch template {
        case .document:
            // Slight zoom reads as a focused writing surface; grid off keeps noise low.
            return ViewportState(scale: 1.06, offsetX: 0, offsetY: 0, showGrid: false)
        case .whiteboard:
            return ViewportState(scale: 1, offsetX: 0, offsetY: 0, showGrid: true)
        case .smartCanvas:
            return ViewportState(scale: 1, offsetX: 0, offsetY: 0, showGrid: true)
        case .flowDiagram:
            // Pull back slightly so the starter diagram reads at a glance.
            return ViewportState(scale: 0.92, offsetX: 0, offsetY: 0, showGrid: true)
        case .blankBoard:
            return ViewportState(scale: 1, offsetX: 0, offsetY: 0, showGrid: false)
        }
    }

    private static func elements(for template: FlowDeskBoardTemplate) -> [CanvasElementRecord] {
        []
    }
}

extension WorkspaceTemplate {
    /// Full board snapshot for a home template with rich starter content.
    func makeInitialCanvasState() -> CanvasBoardState {
        var state = baseTemplate.makeInitialCanvasState()
        state.elements = WorkspaceTemplateSeed.elements(for: id)
        return state
    }
}

private enum WorkspaceTemplateSeed {
    private static let textColor = CanvasRGBAColor.defaultText
    private static let connectorColor = CanvasRGBAColor(red: 0.42, green: 0.47, blue: 0.54, opacity: 1)
    private static let shapeStroke = CanvasRGBAColor(red: 0.36, green: 0.41, blue: 0.49, opacity: 1)

    static func elements(for templateID: String) -> [CanvasElementRecord] {
        switch templateID {
        case "brainstorm-board":
            return brainstormElements()
        case "flowchart":
            return flowchartElements()
        case "product-roadmap":
            return roadmapElements()
        case "meeting-notes":
            return meetingNotesElements()
        case "mind-map":
            return mindMapElements()
        case "kanban-board":
            return kanbanElements()
        case "app-wireframe":
            return wireframeElements()
        case "swot-analysis":
            return swotElements()
        default:
            return []
        }
    }

    private static func brainstormElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Brainstorm: launch week + messy ideas", x: 228, y: 34, width: 610, height: 44, size: 29, bold: true, z: z),
            text("Example use case: solo founder prep before beta push", x: 232, y: 82, width: 640, height: 24, size: 14, z: z + 1),
            text("Last updated: sample", x: 896, y: 84, width: 190, height: 22, size: 12, z: z + 2),
            text("Add your ideas here (rough is fine)", x: 74, y: 118, width: 290, height: 22, size: 13, z: z + 3),
        ]
        z += 4

        let clusters: [(title: String, color: StickyNoteColorPreset, x: Double, y: Double, notes: [String])] = [
            ("Growth channels", .mint, 70, 154, [
                "DM 5 creators we already know (not cold)",
                "Referral challenge? maybe too early",
                "Teaser clips -> need someone to edit",
                "Comparison page draft is half done",
                "Could run one onboarding live session",
            ]),
            ("User pain points", .blush, 500, 162, [
                "Setup still feels like too many choices",
                "People ask what 'canvas' means",
                "Blank board = where do I start?",
                "Recent boards can disappear in long list",
                "Some template copy sounds polished, not human",
            ]),
            ("Retention ideas", .sky, 952, 150, [
                "Weekly nudge with one tiny prompt",
                "Celebrate milestones (lightweight, no confetti overload)",
                "Starter kits by role maybe v2",
                "handoff checklist for small teams",
                "Monthly recap board auto-created (?)",
            ]),
        ]

        for cluster in clusters {
            out.append(shape(kind: .roundedRectangle, x: cluster.x - 26, y: cluster.y - 26, width: 388, height: 404, stroke: shapeStroke, fill: tint(cluster.color.rgba, alpha: 0.18), z: z))
            out.append(text(cluster.title, x: cluster.x - 8, y: cluster.y - 8, width: 320, height: 28, size: 18, bold: true, z: z + 1))
            z += 2
            var noteY = cluster.y + 34
            for (index, line) in cluster.notes.enumerated() {
                let width = 286.0 + Double((index % 3) * 18)
                let height = 50.0 + Double((index % 2) * 16)
                out.append(note(line, x: cluster.x + Double((index % 2) * 8), y: noteY, width: width, height: height, color: cluster.color, z: z))
                z += 1
                noteY += height + 10
            }
        }
        return out
    }

    private static func flowchartElements() -> [CanvasElementRecord] {
        var out: [CanvasElementRecord] = [
            text("Lead qualification flow (working draft)", x: 286, y: 42, width: 560, height: 40, size: 27, bold: true, z: 10),
            text("Example use case: agency triage for inbound requests", x: 286, y: 84, width: 520, height: 24, size: 14, z: 11),
            text("Last updated: sample", x: 840, y: 84, width: 180, height: 22, size: 12, z: 12),
            text("Drag to reorder if your steps differ", x: 286, y: 110, width: 330, height: 22, size: 13, z: 13),
            shape(kind: .roundedRectangle, x: 112, y: 138, width: 280, height: 206, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.16), z: 14),
            text("Intake checklist", x: 132, y: 162, width: 220, height: 24, size: 15, bold: true, z: 15),
            text("• Source + contact channel\n• Budget signal (if any)\n• Urgency / timeline clues\n• Internal owner assigned", x: 132, y: 190, width: 232, height: 130, size: 13, z: 16),
        ]

        let startID = UUID()
        let intakeID = UUID()
        let fitID = UUID()
        let demoID = UUID()
        let nurtureID = UUID()
        let proposalID = UUID()
        let closedID = UUID()

        out += [
            shape(id: startID, kind: .ellipse, x: 460, y: 140, width: 180, height: 72, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.26), z: 20),
            text("Start: new inbound lead", x: 472, y: 165, width: 156, height: 24, size: 14, bold: true, z: 21, alignment: .center),

            shape(id: intakeID, kind: .roundedRectangle, x: 450, y: 250, width: 200, height: 80, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 22),
            text("Collect context\n(company / role / quick need)", x: 468, y: 272, width: 164, height: 48, size: 13, z: 23, alignment: .center),

            shape(id: fitID, kind: .roundedRectangle, x: 430, y: 370, width: 240, height: 90, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lavender.rgba, alpha: 0.22), z: 24),
            text("Decision: is this a real fit?", x: 444, y: 402, width: 212, height: 28, size: 14, bold: true, z: 25, alignment: .center),

            shape(id: demoID, kind: .roundedRectangle, x: 740, y: 500, width: 220, height: 84, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.18), z: 26),
            text("Schedule demo\nwithin 48h if possible", x: 770, y: 526, width: 160, height: 44, size: 13, z: 27, alignment: .center),

            shape(id: nurtureID, kind: .roundedRectangle, x: 140, y: 500, width: 240, height: 84, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.blush.rgba, alpha: 0.2), z: 28),
            text("Add to nurture path\nsend 2 useful resources", x: 172, y: 526, width: 176, height: 44, size: 13, z: 29, alignment: .center),

            shape(id: proposalID, kind: .roundedRectangle, x: 740, y: 640, width: 220, height: 84, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 30),
            text("Send proposal +\nrough timeline", x: 776, y: 666, width: 148, height: 44, size: 13, z: 31, alignment: .center),

            shape(id: closedID, kind: .ellipse, x: 740, y: 780, width: 220, height: 72, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.26), z: 32),
            text("End: Qualified opportunity", x: 772, y: 806, width: 156, height: 24, size: 13, bold: true, z: 33, alignment: .center),
        ]

        out += [
            connector(from: startID, to: intakeID, startEdge: .bottom, endEdge: .top, label: "", z: 34),
            connector(from: intakeID, to: fitID, startEdge: .bottom, endEdge: .top, label: "", z: 35),
            connector(from: fitID, to: demoID, startEdge: .right, endEdge: .top, label: "Yes", z: 36),
            connector(from: fitID, to: nurtureID, startEdge: .left, endEdge: .top, label: "No", z: 37),
            connector(from: demoID, to: proposalID, startEdge: .bottom, endEdge: .top, label: "", z: 38),
            connector(from: proposalID, to: closedID, startEdge: .bottom, endEdge: .top, label: "", z: 39),
            shape(kind: .roundedRectangle, x: 1020, y: 514, width: 232, height: 220, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.14), z: 40),
            text("SLA notes", x: 1040, y: 538, width: 180, height: 26, size: 15, bold: true, z: 41),
            text("First reply target: < 6h\n\nIf no owner in 12h,\nescalate in #sales-intake.\n\nProposal sent > 4 days?\ntrigger follow-up reminder.", x: 1040, y: 568, width: 192, height: 154, size: 12.5, z: 42),
        ]
        return out
    }

    private static func roadmapElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Roadmap board - current thinking", x: 170, y: 42, width: 840, height: 40, size: 30, bold: true, z: z),
            text("Example use case: product lead planning next 2 quarters", x: 170, y: 84, width: 620, height: 24, size: 14, z: z + 1),
            text("Last updated: sample", x: 836, y: 84, width: 190, height: 22, size: 12, z: z + 2),
            text("Drag to reorder as priorities shift", x: 170, y: 108, width: 300, height: 22, size: 13, z: z + 3),
            shape(kind: .roundedRectangle, x: 170, y: 676, width: 1030, height: 164, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.96, green: 0.97, blue: 0.99, opacity: 0.9), z: z + 4),
            text("Risks + dependencies (quick reality check)", x: 196, y: 700, width: 460, height: 28, size: 17, bold: true, z: z + 5),
            text("• API rate limits may block dashboard rollout\n• Hiring gap: no dedicated QA yet\n• Need legal review before usage insights ship", x: 196, y: 730, width: 470, height: 92, size: 13, z: z + 6),
            text("Confidence\nNow: High\nNext: Medium\nLater: Low-ish", x: 946, y: 702, width: 210, height: 112, size: 13, z: z + 7, alignment: .center),
        ]
        z += 8

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, items: [String])] = [
            ("Now", .mint, 80, [
                "Stabilize offline sync (still flaky on large boards)",
                "Ship new template gallery copy pass",
                "PDF export quality: tighten spacing + fonts",
                "Refine onboarding empty states",
            ]),
            ("Next", .sky, 470, [
                "Board comments (lightweight, not full chat)",
                "Reusable style presets v1",
                "Milestone dashboard draft",
                "Large-board performance pass",
            ]),
            ("Later", .lavender, 860, [
                "AI assist for organizing messy boards",
                "Cross-board linking",
                "Shared team template packs",
                "Usage insights (if privacy review passes)",
            ]),
        ]

        for column in columns {
            out.append(shape(kind: .roundedRectangle, x: column.x - 24, y: 142, width: 340, height: 510, stroke: shapeStroke, fill: tint(column.color.rgba, alpha: 0.16), z: z))
            out.append(text(column.title, x: column.x, y: 166, width: 292, height: 30, size: 24, bold: true, z: z + 1))
            z += 2

            var y = 220.0
            for (index, item) in column.items.enumerated() {
                let h = 74.0 + Double((index % 3) * 10)
                out.append(note(item, x: column.x + Double((index % 2) * 6), y: y, width: 284 + Double((index % 2) * 12), height: h, color: column.color, z: z))
                z += 1
                y += h + 16
            }
        }
        return out
    }

    private static func meetingNotesElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            shape(kind: .roundedRectangle, x: 100, y: 46, width: 1100, height: 800, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.96, green: 0.97, blue: 0.99, opacity: 0.95), z: z),
            text("Weekly product sync (notes in progress)", x: 132, y: 78, width: 700, height: 40, size: 29, bold: true, z: z + 1),
            text("Example use case: cross-functional weekly check-in", x: 132, y: 122, width: 500, height: 24, size: 13, z: z + 2),
            text("Last updated: sample", x: 990, y: 122, width: 170, height: 22, size: 12, z: z + 3),
            text("Add your notes here - leave rough points", x: 132, y: 146, width: 340, height: 22, size: 12, z: z + 4),
            shape(kind: .roundedRectangle, x: 132, y: 168, width: 1026, height: 70, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.12), z: z + 5),
            text("Attendees: Priya, Ramon, Elise, Jun, Sam (joined late)", x: 156, y: 186, width: 620, height: 22, size: 13, z: z + 6),
            text("Decision needed today: ship export polish now or defer", x: 156, y: 208, width: 620, height: 22, size: 13, z: z + 7),
        ]
        z += 8

        let sections: [(title: String, x: Double, y: Double, width: Double, body: String)] = [
            ("Agenda", 132, 176, 496, "1. Release status quick scan\n2. User feedback themes\n3. Risks + dependencies\n4. Decisions we can actually make today"),
            ("Discussion notes", 132, 356, 496, "• Beta folks liked faster loading.\n• Still confusion around connector handles.\n• Copy on templates feels too polished right now.\n• Need one owner for performance goal (who?)"),
            ("Action items", 662, 176, 496, "• Priya - onboarding script draft by Thu.\n• Ramon - connector snapping fix this sprint.\n• Elise - launch checklist refresh.\n• Everyone - drop 1 blocker in this board before Friday."),
            ("Parking lot", 662, 470, 496, "• Board-level comments vs element-level first?\n• Markdown export priority uncertain.\n• Could reuse card components from home view."),
        ]

        for section in sections {
            out.append(shape(kind: .roundedRectangle, x: section.x, y: section.y, width: section.width, height: 246, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.1), z: z))
            out.append(text(section.title, x: section.x + 18, y: section.y + 18, width: section.width - 36, height: 30, size: 20, bold: true, z: z + 1))
            out.append(text(section.body, x: section.x + 18, y: section.y + 58, width: section.width - 36, height: 168, size: 14, z: z + 2))
            z += 3
        }
        return out
    }

    private static func mindMapElements() -> [CanvasElementRecord] {
        var out: [CanvasElementRecord] = [
            shape(kind: .roundedRectangle, x: 300, y: 36, width: 760, height: 88, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.96, green: 0.97, blue: 0.99, opacity: 0.88), z: 7),
            text("Q3 launch strategy", x: 500, y: 388, width: 220, height: 44, size: 22, bold: true, z: 20, alignment: .center),
            text("Example use case: planning a rollout with a tiny team", x: 338, y: 54, width: 470, height: 24, size: 14, z: 8),
            text("Last updated: sample", x: 852, y: 54, width: 170, height: 22, size: 12, z: 9),
            text("Add your ideas here and branch freely", x: 338, y: 78, width: 300, height: 22, size: 13, z: 10),
            text("Legend: thick branch = critical path", x: 818, y: 78, width: 220, height: 22, size: 12, z: 11),
        ]

        let centerID = UUID()
        out.append(shape(id: centerID, kind: .ellipse, x: 470, y: 360, width: 280, height: 108, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.28), z: 19))

        let branches: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, subs: [String])] = [
            ("Messaging", 180, 204, .blush, ["Value prop draft", "Proof points (collect 2 more)"]),
            ("Channels", 884, 214, .mint, ["Owned email", "Partner co-marketing maybe"]),
            ("Sales enablement", 910, 516, .sky, ["Demo script rev2", "Objection handling notes"]),
            ("Launch ops", 166, 546, .lavender, ["Timeline owner", "Readiness checklist"]),
            ("Customer success", 502, 646, .mint, ["Onboarding touchpoints", "Success metrics baseline"]),
        ]

        var z = 30
        for branch in branches {
            let branchID = UUID()
            let branchWidth = branch.title == "Customer success" ? 266.0 : 230.0
            out.append(shape(id: branchID, kind: .roundedRectangle, x: branch.x, y: branch.y, width: branchWidth, height: 82, stroke: shapeStroke, fill: tint(branch.color.rgba, alpha: 0.22), z: z))
            out.append(text(branch.title, x: branch.x + 16, y: branch.y + 28, width: 198, height: 26, size: 16, bold: true, z: z + 1, alignment: .center))
            out.append(connector(from: centerID, to: branchID, startEdge: .right, endEdge: .left, style: .arrow, z: z + 2))
            z += 3

            var subX = branch.x + 10
            var subY = branch.y + 98
            for sub in branch.subs {
                let subID = UUID()
                out.append(shape(id: subID, kind: .roundedRectangle, x: subX, y: subY, width: 210, height: 64, stroke: shapeStroke, fill: tint(branch.color.rgba, alpha: 0.12), z: z))
                out.append(text(sub, x: subX + 14, y: subY + 22, width: 182, height: 22, size: 13, z: z + 1, alignment: .center))
                out.append(connector(from: branchID, to: subID, startEdge: .bottom, endEdge: .top, style: .straight, z: z + 2))
                z += 3
                subY += 76
                if subY > 760 {
                    subY = branch.y + 98
                    subX += 228
                }
            }
        }
        return out
    }

    private static func kanbanElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Sprint board (real work, not pretty)", x: 130, y: 40, width: 960, height: 42, size: 30, bold: true, z: z),
            text("Example use case: small product squad weekly board", x: 130, y: 84, width: 430, height: 24, size: 14, z: z + 1),
            text("Last updated: sample", x: 900, y: 84, width: 170, height: 22, size: 12, z: z + 2),
            text("Drag to reorder cards within a lane", x: 130, y: 108, width: 280, height: 22, size: 13, z: z + 3),
        ]
        z += 4

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, cards: [String])] = [
            ("To Do", .lemon, 90, [
                "Finalize launch FAQ (missing 2 answers)",
                "Review accessibility contrast tokens",
                "Set up beta feedback board",
                "Write release announcement draft",
                "Check analytics event naming",
            ]),
            ("In Progress", .sky, 480, [
                "Template realism copy pass",
                "Improve connector hit-testing",
                "Benchmark rendering on large boards",
                "Prep support macro snippets",
            ]),
            ("Done", .mint, 870, [
                "Migrate board payload to format v1",
                "Refactor canvas undo grouping",
                "Align empty-state copy across home",
                "Fix missing icon in sidebar",
            ]),
        ]

        for column in columns {
            out.append(shape(kind: .roundedRectangle, x: column.x - 20, y: 140, width: 330, height: 620, stroke: shapeStroke, fill: tint(column.color.rgba, alpha: 0.15), z: z))
            out.append(text(column.title, x: column.x, y: 168, width: 290, height: 30, size: 22, bold: true, z: z + 1))
            z += 2

            var y = 226.0
            for (index, card) in column.cards.enumerated() {
                let w = 276.0 + Double((index % 2) * 14)
                let h = 80.0 + Double((index % 3) * 12)
                out.append(note(card, x: column.x + Double((index % 2) * 5), y: y, width: w, height: h, color: column.color, z: z))
                z += 1
                y += h + 12
            }
        }
        return out
    }

    private static func wireframeElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Mobile app wireframe - scratchpad", x: 222, y: 42, width: 560, height: 42, size: 30, bold: true, z: z),
            text("Example use case: quick planning before moving to Figma", x: 222, y: 84, width: 540, height: 24, size: 14, z: z + 1),
            text("Last updated: sample", x: 846, y: 84, width: 170, height: 22, size: 12, z: z + 2),
            text("Add your ideas here / annotate decisions", x: 700, y: 214, width: 310, height: 22, size: 13, z: z + 3),
            shape(kind: .roundedRectangle, x: 684, y: 170, width: 410, height: 330, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.09), z: z + 4),
            text("Open questions", x: 708, y: 196, width: 210, height: 24, size: 16, bold: true, z: z + 5),
            text("• Is search sticky on scroll?\n• Need one-tap quick add?\n• Should Card B be personalized?\n• Empty-state illustration maybe too loud", x: 708, y: 228, width: 360, height: 212, size: 13, z: z + 6),
        ]
        z += 7

        out += [
            shape(kind: .roundedRectangle, x: 240, y: 130, width: 390, height: 760, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.97, green: 0.97, blue: 0.98, opacity: 1), z: z),
            text("App header", x: 270, y: 156, width: 330, height: 28, size: 16, bold: true, z: z + 1, alignment: .center),
            shape(kind: .roundedRectangle, x: 270, y: 198, width: 330, height: 64, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.14), z: z + 2),
            text("Search bar", x: 286, y: 220, width: 298, height: 24, size: 13, z: z + 3),
            shape(kind: .roundedRectangle, x: 270, y: 286, width: 330, height: 176, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lavender.rgba, alpha: 0.14), z: z + 4),
            text("Hero card", x: 286, y: 364, width: 298, height: 24, size: 14, bold: true, z: z + 5, alignment: .center),
            shape(kind: .roundedRectangle, x: 270, y: 484, width: 160, height: 150, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.14), z: z + 6),
            shape(kind: .roundedRectangle, x: 444, y: 492, width: 154, height: 142, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.14), z: z + 7),
            text("Card A", x: 318, y: 548, width: 64, height: 22, size: 12, bold: true, z: z + 8, alignment: .center),
            text("Card B", x: 488, y: 548, width: 64, height: 22, size: 12, bold: true, z: z + 9, alignment: .center),
            shape(kind: .roundedRectangle, x: 270, y: 658, width: 330, height: 136, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.14), z: z + 10),
            text("Bottom navigation", x: 286, y: 714, width: 298, height: 24, size: 13, z: z + 11, alignment: .center),
        ]

        out += [
            text("1) Keep spacing mostly on 8pt grid", x: 700, y: 250, width: 360, height: 24, size: 13, z: z + 12),
            text("2) Primary action should stay above fold", x: 700, y: 286, width: 360, height: 24, size: 13, z: z + 13),
            text("3) Check readability at 13pt body text", x: 700, y: 322, width: 360, height: 24, size: 13, z: z + 14),
            text("4) TODO: decide if hero card needs image", x: 700, y: 356, width: 360, height: 24, size: 13, z: z + 15),
            shape(kind: .roundedRectangle, x: 708, y: 526, width: 350, height: 210, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.blush.rgba, alpha: 0.1), z: z + 16),
            text("Interaction notes", x: 730, y: 548, width: 220, height: 24, size: 15, bold: true, z: z + 17),
            text("Tap hero -> details\nLong press card -> quick actions\nSwipe right on card -> archive\nBottom nav center tab = compose", x: 730, y: 576, width: 302, height: 132, size: 13, z: z + 18),
        ]
        return out
    }

    private static func swotElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("SWOT analysis - launch prep", x: 180, y: 36, width: 820, height: 42, size: 30, bold: true, z: z),
            text("Example use case: team alignment before go/no-go decision", x: 180, y: 80, width: 620, height: 24, size: 14, z: z + 1),
            text("Last updated: sample", x: 882, y: 80, width: 170, height: 22, size: 12, z: z + 2),
            text("Add your ideas here - keep points short", x: 180, y: 104, width: 300, height: 22, size: 13, z: z + 3),
            shape(kind: .roundedRectangle, x: 160, y: 780, width: 950, height: 110, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.96, green: 0.97, blue: 0.99, opacity: 0.92), z: z + 4),
            text("Next 14 days: validate top risk assumptions and confirm launch threshold.", x: 188, y: 812, width: 740, height: 28, size: 15, bold: true, z: z + 5),
            text("Owner: PM + Eng Lead | Confidence: medium-low", x: 188, y: 842, width: 500, height: 24, size: 13, z: z + 6),
        ]
        z += 7

        let boxes: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, bullets: String)] = [
            ("Strengths", 120, 150, .mint, "• Fast canvas interactions\n• Interface feels clean\n• Template onboarding is getting stronger"),
            ("Weaknesses", 640, 150, .blush, "• Collaboration still basic\n• Export controls are limited\n• Connector editing has a learning curve"),
            ("Opportunities", 120, 470, .sky, "• More teams moving to async planning\n• Docs -> canvas migration trend\n• Potential partnerships with creator communities"),
            ("Threats", 640, 470, .lavender, "• Bigger incumbents with integrated suites\n• Price pressure from bundles\n• Churn risk if reliability slips again"),
        ]

        for box in boxes {
            out.append(shape(kind: .roundedRectangle, x: box.x, y: box.y, width: 460, height: 270, stroke: shapeStroke, fill: tint(box.color.rgba, alpha: 0.18), z: z))
            out.append(text(box.title, x: box.x + 20, y: box.y + 20, width: 420, height: 30, size: 22, bold: true, z: z + 1))
            out.append(text(box.bullets, x: box.x + 20, y: box.y + 68, width: 420, height: 180, size: 14, z: z + 2))
            z += 3
        }
        return out
    }

    private static func text(
        _ content: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        size: Double,
        bold: Bool = false,
        z: Int,
        alignment: TextBlockAlignment = .leading
    ) -> CanvasElementRecord {
        CanvasElementRecord(
            kind: .textBlock,
            x: x,
            y: y,
            width: width,
            height: height,
            zIndex: z,
            textBlock: TextBlockPayload(
                text: content,
                fontSize: size,
                isBold: bold,
                color: textColor,
                alignment: alignment
            )
        )
    }

    private static func note(
        _ content: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        color: StickyNoteColorPreset,
        z: Int
    ) -> CanvasElementRecord {
        CanvasElementRecord(
            kind: .stickyNote,
            x: x,
            y: y,
            width: width,
            height: height,
            zIndex: z,
            stickyNote: StickyNotePayload(
                text: content,
                backgroundColor: color.rgba,
                fontSize: 13.5,
                isBold: false,
                textColor: textColor
            )
        )
    }

    private static func shape(
        id: UUID = UUID(),
        kind: FlowDeskShapeKind,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        stroke: CanvasRGBAColor,
        fill: CanvasRGBAColor,
        z: Int
    ) -> CanvasElementRecord {
        CanvasElementRecord(
            id: id,
            kind: .shape,
            x: x,
            y: y,
            width: width,
            height: height,
            zIndex: z,
            shapePayload: ShapePayload(
                kind: kind,
                strokeColor: stroke,
                fillColor: fill,
                lineWidth: 2,
                cornerRadius: 16
            )
        )
    }

    private static func connector(
        from startID: UUID,
        to endID: UUID,
        startEdge: ConnectorEdge,
        endEdge: ConnectorEdge,
        label: String = "",
        style: ConnectorLineStyle = .arrow,
        z: Int
    ) -> CanvasElementRecord {
        CanvasElementRecord(
            kind: .connector,
            x: 0,
            y: 0,
            width: 0,
            height: 0,
            zIndex: z,
            connectorPayload: ConnectorPayload(
                startElementID: startID,
                endElementID: endID,
                startEdge: startEdge,
                endEdge: endEdge,
                startT: 0.5,
                endT: 0.5,
                style: style,
                strokeColor: connectorColor,
                lineWidth: 2,
                label: label
            )
        )
    }

    private static func tint(_ color: CanvasRGBAColor, alpha: Double) -> CanvasRGBAColor {
        CanvasRGBAColor(red: color.red, green: color.green, blue: color.blue, opacity: alpha)
    }
}
