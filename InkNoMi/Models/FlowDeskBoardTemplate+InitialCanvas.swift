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
            text("Brainstorm board", x: 226, y: 122, width: 520, height: 48, size: 34, bold: true, z: z),
            text("Use case label: rough launch-week idea sorting", x: 228, y: 174, width: 510, height: 26, size: 15, z: z + 1),
        ]
        z += 2

        let clusters: [(title: String, color: StickyNoteColorPreset, x: Double, y: Double, notes: [String])] = [
            ("Growth channels", .mint, 220, 220, [
                "DM 5 creators we already know (not cold)",
                "Referral challenge? maybe too early",
                "Teaser clips -> need someone to edit",
                "Comparison page draft is half done",
                "Could run one onboarding live session",
            ]),
            ("User pain points", .blush, 610, 220, [
                "Setup still feels like too many choices",
                "People ask what 'canvas' means",
                "Blank board = where do I start?",
                "Recent boards can disappear in long list",
                "Some template copy sounds polished, not human",
            ]),
            ("Retention ideas", .sky, 220, 560, [
                "Weekly nudge with one tiny prompt",
                "Celebrate milestones (lightweight, no confetti overload)",
                "Starter kits by role maybe v2",
                "handoff checklist for small teams",
                "Monthly recap board auto-created (?)",
            ]),
            ("Risks and blockers", .lemon, 610, 560, [
                "No clear owner for launch day support",
                "Still unsure if pricing page is understandable",
                "Docs screenshots are two versions behind",
                "Onboarding email draft sounds too formal",
                "Could break if import edge cases spike",
            ]),
        ]

        for cluster in clusters {
            out.append(shape(kind: .roundedRectangle, x: cluster.x - 10, y: cluster.y, width: 360, height: 430, stroke: CanvasRGBAColor(red: 0.2, green: 0.25, blue: 0.33, opacity: 0.35), fill: tint(cluster.color.rgba, alpha: 0.2), z: z, cornerRadius: 24))
            out.append(shape(kind: .roundedRectangle, x: cluster.x + 20, y: cluster.y + 14, width: 300, height: 48, stroke: shapeStroke, fill: CanvasRGBAColor(red: 1, green: 1, blue: 1, opacity: 0.88), z: z + 1, cornerRadius: 16))
            out.append(text(cluster.title, x: cluster.x + 24, y: cluster.y + 26, width: 292, height: 24, size: 17, bold: true, z: z + 2, alignment: .center))
            z += 2
            var noteY = cluster.y + 78
            for (index, line) in cluster.notes.enumerated() {
                let width = 284.0 + Double((index % 2) * 14)
                let height = 46.0 + Double((index % 2) * 12)
                out.append(note(line, x: cluster.x + Double((index % 2) * 8), y: noteY, width: width, height: height, color: cluster.color, z: z))
                z += 1
                noteY += height + 8
            }
        }
        return out
    }

    private static func flowchartElements() -> [CanvasElementRecord] {
        var out: [CanvasElementRecord] = [
            text("Flowchart", x: 460, y: 122, width: 320, height: 48, size: 34, bold: true, z: 10, alignment: .center),
            text("Use case label: inbound lead qualification", x: 446, y: 174, width: 370, height: 24, size: 15, z: 11, alignment: .center),
        ]

        let startID = UUID()
        let intakeID = UUID()
        let fitID = UUID()
        let demoID = UUID()
        let nurtureID = UUID()
        let proposalID = UUID()
        let closedID = UUID()

        out += [
            shape(id: startID, kind: .ellipse, x: 640, y: 220, width: 200, height: 68, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.24), z: 20),
            text("Start", x: 690, y: 244, width: 100, height: 24, size: 14, bold: true, z: 21, alignment: .center),

            shape(id: intakeID, kind: .roundedRectangle, x: 620, y: 320, width: 240, height: 78, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 22),
            text("Capture lead details", x: 650, y: 348, width: 180, height: 24, size: 13, z: 23, alignment: .center),

            shape(id: fitID, kind: .roundedRectangle, x: 620, y: 430, width: 240, height: 78, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 24),
            text("Confirm use-case fit", x: 648, y: 458, width: 184, height: 24, size: 13, z: 25, alignment: .center),

            shape(id: proposalID, kind: .roundedRectangle, x: 620, y: 540, width: 240, height: 78, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 26),
            text("Prepare solution demo", x: 644, y: 568, width: 194, height: 24, size: 13, z: 27, alignment: .center),

            shape(id: closedID, kind: .roundedRectangle, x: 620, y: 650, width: 240, height: 78, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 28),
            text("Send proposal", x: 678, y: 678, width: 124, height: 24, size: 13, z: 29, alignment: .center),

            shape(id: demoID, kind: .rectangle, x: 610, y: 760, width: 260, height: 90, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lavender.rgba, alpha: 0.24), z: 30),
            text("Decision: Budget approved?", x: 632, y: 792, width: 216, height: 24, size: 13, bold: true, z: 31, alignment: .center),

            shape(id: nurtureID, kind: .rectangle, x: 960, y: 760, width: 260, height: 90, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.24), z: 32),
            text("Decision: Timeline workable?", x: 982, y: 792, width: 216, height: 24, size: 13, bold: true, z: 33, alignment: .center),
        ]

        let approvedID = UUID()
        let revisitID = UUID()
        let launchID = UUID()
        out += [
            shape(id: approvedID, kind: .roundedRectangle, x: 960, y: 640, width: 240, height: 76, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.18), z: 34),
            text("Branch outcome: schedule kickoff", x: 980, y: 666, width: 200, height: 24, size: 12.5, z: 35, alignment: .center),
            shape(id: revisitID, kind: .roundedRectangle, x: 260, y: 760, width: 260, height: 90, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.blush.rgba, alpha: 0.2), z: 36),
            text("Branch outcome: move to nurture", x: 284, y: 792, width: 212, height: 24, size: 12.5, z: 37, alignment: .center),
            shape(id: launchID, kind: .ellipse, x: 960, y: 860, width: 240, height: 62, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.24), z: 38),
            text("End", x: 1060, y: 881, width: 40, height: 24, size: 13, bold: true, z: 39, alignment: .center),
        ]

        out += [
            connector(from: startID, to: intakeID, startEdge: .bottom, endEdge: .top, label: "", z: 34),
            connector(from: intakeID, to: fitID, startEdge: .bottom, endEdge: .top, label: "", z: 35),
            connector(from: fitID, to: proposalID, startEdge: .bottom, endEdge: .top, label: "", z: 36),
            connector(from: proposalID, to: closedID, startEdge: .bottom, endEdge: .top, label: "", z: 37),
            connector(from: closedID, to: demoID, startEdge: .bottom, endEdge: .top, label: "", z: 38),
            connector(from: demoID, to: approvedID, startEdge: .right, endEdge: .left, label: "Yes", z: 39),
            connector(from: demoID, to: revisitID, startEdge: .left, endEdge: .right, label: "No", z: 40),
            connector(from: approvedID, to: nurtureID, startEdge: .bottom, endEdge: .top, label: "", z: 41),
            connector(from: nurtureID, to: launchID, startEdge: .bottom, endEdge: .top, label: "Yes", z: 42),
            connector(from: nurtureID, to: revisitID, startEdge: .left, endEdge: .bottom, label: "No", z: 43),
        ]
        return out
    }

    private static func roadmapElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Roadmap", x: 226, y: 122, width: 300, height: 48, size: 34, bold: true, z: z),
            text("Use case label: quarterly planning with trade-offs", x: 228, y: 174, width: 470, height: 24, size: 15, z: z + 1),
        ]
        z += 2

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, items: [String])] = [
            ("Now", .mint, 220, [
                "Stabilize offline sync (still flaky on large boards)",
                "Ship new template gallery copy pass",
                "PDF export quality: tighten spacing + fonts",
                "Refine onboarding empty states",
                "Fix duplicate board name edge case",
            ]),
            ("Next", .sky, 590, [
                "Board comments (lightweight, not full chat)",
                "Reusable style presets v1",
                "Milestone dashboard draft",
                "Large-board performance pass",
                "Smarter template recommendations",
            ]),
            ("Later", .lavender, 960, [
                "AI assist for organizing messy boards",
                "Cross-board linking",
                "Shared team template packs",
                "Usage insights (if privacy review passes)",
                "Lightweight mobile companion",
            ]),
        ]

        for column in columns {
            out.append(shape(kind: .roundedRectangle, x: column.x - 10, y: 230, width: 320, height: 520, stroke: shapeStroke, fill: tint(column.color.rgba, alpha: 0.16), z: z))
            out.append(text(column.title, x: column.x + 10, y: 250, width: 300, height: 32, size: 24, bold: true, z: z + 1, alignment: .center))
            z += 2

            var y = 300.0
            for (index, item) in column.items.enumerated() {
                let h = 68.0 + Double((index % 3) * 8)
                out.append(note(item, x: column.x + 6, y: y, width: 282, height: h, color: column.color, z: z))
                let pillColor: StickyNoteColorPreset = index == 0 ? .mint : (index == 1 || index == 2 ? .sky : .blush)
                let priority = index == 0 ? "High" : (index < 3 ? "Med" : "Low")
                out.append(shape(kind: .roundedRectangle, x: column.x + 214, y: y + 8, width: 66, height: 24, stroke: shapeStroke, fill: tint(pillColor.rgba, alpha: 0.32), z: z + 1, cornerRadius: 12))
                out.append(text(priority, x: column.x + 224, y: y + 12, width: 46, height: 16, size: 11.5, bold: true, z: z + 2, alignment: .center))
                z += 1
                y += h + 12
            }
        }
        return out
    }

    private static func meetingNotesElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Meeting Notes", x: 230, y: 122, width: 360, height: 48, size: 34, bold: true, z: z),
            shape(kind: .roundedRectangle, x: 220, y: 220, width: 360, height: 620, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.13), z: z + 1),
            shape(kind: .roundedRectangle, x: 610, y: 220, width: 360, height: 620, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.12), z: z + 2),
            shape(kind: .roundedRectangle, x: 1000, y: 220, width: 360, height: 620, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.12), z: z + 3),
        ]
        z += 4
        out += [
            text("Meeting details", x: 248, y: 246, width: 320, height: 30, size: 20, bold: true, z: z),
            text("Date: Tue 10:00", x: 250, y: 286, width: 170, height: 24, size: 13, z: z + 1),
            text("Host: Priya", x: 250, y: 314, width: 170, height: 24, size: 13, z: z + 2),
            text("Attendees: Priya, Ramon, Elise, Jun", x: 250, y: 342, width: 300, height: 24, size: 13, z: z + 3),
            text("Agenda", x: 248, y: 382, width: 320, height: 30, size: 20, bold: true, z: z + 4),
            note("Release status + blockers", x: 250, y: 424, width: 292, height: 62, color: .lemon, z: z + 5),
            note("Template quality pass", x: 252, y: 496, width: 286, height: 58, color: .lemon, z: z + 6),
            note("Decide launch freeze date", x: 252, y: 564, width: 286, height: 58, color: .lemon, z: z + 7),
            text("Notes", x: 640, y: 246, width: 300, height: 30, size: 20, bold: true, z: z + 8),
            note("Beta users liked speed, still confused by connector handles.", x: 638, y: 288, width: 300, height: 90, color: .sky, z: z + 9),
            note("Onboarding copy sounds too polished; make it more human.", x: 636, y: 388, width: 304, height: 86, color: .sky, z: z + 10),
            note("Need one owner for perf budget and weekly check.", x: 640, y: 484, width: 298, height: 84, color: .sky, z: z + 11),
            text("Decisions", x: 640, y: 584, width: 300, height: 30, size: 20, bold: true, z: z + 12),
            note("Ship template refresh in this sprint, not next.", x: 638, y: 624, width: 300, height: 78, color: .sky, z: z + 13),
            note("Defer markdown export polish by one release.", x: 640, y: 710, width: 296, height: 76, color: .sky, z: z + 14),
            text("Action items", x: 1030, y: 246, width: 300, height: 30, size: 20, bold: true, z: z + 15),
            note("Ramon: fix connector snapping by Thu", x: 1030, y: 288, width: 300, height: 72, color: .mint, z: z + 16),
            note("Elise: rewrite 8 template notes with natural wording", x: 1030, y: 368, width: 302, height: 84, color: .mint, z: z + 17),
            note("Jun: verify iPhone SE viewport clipping", x: 1032, y: 460, width: 296, height: 72, color: .mint, z: z + 18),
            note("Priya: send launch checklist v3 by Friday", x: 1032, y: 540, width: 296, height: 76, color: .mint, z: z + 19),
            note("All: add one blocker before standup tomorrow", x: 1030, y: 624, width: 302, height: 78, color: .mint, z: z + 20),
        ]
        return out
    }

    private static func mindMapElements() -> [CanvasElementRecord] {
        var out: [CanvasElementRecord] = [
            text("Mind Map", x: 232, y: 122, width: 280, height: 48, size: 34, bold: true, z: 7),
        ]

        let centerID = UUID()
        out.append(shape(id: centerID, kind: .ellipse, x: 720, y: 430, width: 200, height: 94, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.28), z: 19))
        out.append(text("InkNoMi", x: 760, y: 462, width: 120, height: 24, size: 20, bold: true, z: 20, alignment: .center))

        let branches: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, subs: [String])] = [
            ("Users", 450, 260, .mint, ["Solo creators", "Tiny startup teams", "Student builders"]),
            ("Product", 980, 300, .sky, ["Template realism", "Fast connector editing", "Smooth onboarding"]),
            ("Revenue", 1020, 600, .lemon, ["Pro monthly", "Team annual", "Add-on exports"]),
            ("Marketing", 520, 650, .blush, ["Founder content", "Partner launches", "Referral loops"]),
            ("Risks", 240, 520, .lavender, ["Stability regressions", "Slow collaboration roadmap", "Pricing confusion"]),
        ]

        var z = 30
        for branch in branches {
            let branchID = UUID()
            out.append(shape(id: branchID, kind: .roundedRectangle, x: branch.x, y: branch.y, width: 220, height: 72, stroke: shapeStroke, fill: tint(branch.color.rgba, alpha: 0.22), z: z))
            out.append(text(branch.title, x: branch.x + 20, y: branch.y + 24, width: 180, height: 24, size: 16, bold: true, z: z + 1, alignment: .center))
            out.append(connector(from: centerID, to: branchID, startEdge: .left, endEdge: .right, style: .arrow, z: z + 2))
            z += 3

            var subX = branch.x + 10
            var subY = branch.y + 98
            for sub in branch.subs {
                let subID = UUID()
                out.append(shape(id: subID, kind: .roundedRectangle, x: subX, y: subY, width: 210, height: 58, stroke: shapeStroke, fill: tint(branch.color.rgba, alpha: 0.12), z: z))
                out.append(text(sub, x: subX + 12, y: subY + 18, width: 186, height: 22, size: 12.5, z: z + 1, alignment: .center))
                out.append(connector(from: branchID, to: subID, startEdge: .bottom, endEdge: .top, style: .straight, z: z + 2))
                z += 3
                subY += 68
                if subY > 860 {
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
            text("Kanban", x: 230, y: 122, width: 220, height: 48, size: 34, bold: true, z: z),
        ]
        z += 1

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, cards: [String])] = [
            ("Backlog", .lemon, 220, [
                "Finalize launch FAQ (missing 2 answers)",
                "Review accessibility contrast tokens",
                "Set up beta feedback board",
                "Write release announcement draft",
                "Check analytics event naming",
            ]),
            ("In Progress", .sky, 520, [
                "Template realism copy pass",
                "Improve connector hit-testing",
                "Benchmark rendering on large boards",
                "Prep support macro snippets",
                "Rewrite empty-state hints",
            ]),
            ("Review", .lavender, 820, [
                "Board creation flow QA checklist",
                "Import/export weird file samples",
                "Flowchart seed spacing tune-up",
                "Meeting notes wording pass",
                "Smoke test on iPad split view",
            ]),
            ("Done", .mint, 1120, [
                "Migrate board payload to format v1",
                "Refactor canvas undo grouping",
                "Align empty-state copy across home",
                "Fix missing icon in sidebar",
                "Stabilize template thumbnails",
            ]),
        ]

        for column in columns {
            out.append(shape(kind: .roundedRectangle, x: column.x - 12, y: 220, width: 280, height: 620, stroke: shapeStroke, fill: tint(column.color.rgba, alpha: 0.15), z: z))
            out.append(text(column.title, x: column.x, y: 248, width: 252, height: 30, size: 20, bold: true, z: z + 1, alignment: .center))
            z += 2

            var y = 294.0
            for (index, card) in column.cards.enumerated() {
                let w = 238.0 + Double((index % 2) * 8)
                let h = 80.0 + Double((index % 3) * 12)
                out.append(note(card, x: column.x + Double((index % 2) * 4), y: y, width: w, height: h, color: column.color, z: z))
                z += 1
                y += h + 12
            }
        }
        return out
    }

    private static func wireframeElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("App Wireframe", x: 224, y: 122, width: 320, height: 48, size: 34, bold: true, z: z),
        ]
        z += 1

        out += [
            shape(kind: .roundedRectangle, x: 280, y: 220, width: 360, height: 690, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.97, green: 0.97, blue: 0.98, opacity: 1), z: z, cornerRadius: 42),
            shape(kind: .roundedRectangle, x: 306, y: 250, width: 308, height: 30, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.1), z: z + 1, cornerRadius: 10),
            text("Status bar", x: 420, y: 258, width: 80, height: 16, size: 11, z: z + 2, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 292, width: 308, height: 72, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.16), z: z + 3),
            text("Header", x: 430, y: 320, width: 60, height: 20, size: 14, bold: true, z: z + 4, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 378, width: 308, height: 160, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lavender.rgba, alpha: 0.16), z: z + 5),
            text("Hero placeholder", x: 400, y: 448, width: 120, height: 24, size: 13, bold: true, z: z + 6, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 552, width: 308, height: 180, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.14), z: z + 7),
            text("Card list", x: 430, y: 632, width: 60, height: 20, size: 13, bold: true, z: z + 8, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 742, width: 308, height: 58, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.2), z: z + 9),
            text("CTA", x: 444, y: 762, width: 32, height: 20, size: 13, bold: true, z: z + 10, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 810, width: 308, height: 74, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.12), z: z + 11),
            text("Bottom nav", x: 418, y: 838, width: 84, height: 20, size: 13, z: z + 12, alignment: .center),
        ]

        out += [
            shape(kind: .roundedRectangle, x: 760, y: 230, width: 560, height: 420, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.blush.rgba, alpha: 0.1), z: z + 13),
            text("Side annotations", x: 790, y: 258, width: 220, height: 24, size: 16, bold: true, z: z + 14),
            text("phone frame", x: 792, y: 300, width: 260, height: 24, size: 13, z: z + 15),
            text("status bar", x: 792, y: 332, width: 260, height: 24, size: 13, z: z + 16),
            text("header", x: 792, y: 364, width: 260, height: 24, size: 13, z: z + 17),
            text("hero placeholder", x: 792, y: 396, width: 260, height: 24, size: 13, z: z + 18),
            text("card list", x: 792, y: 428, width: 260, height: 24, size: 13, z: z + 19),
            text("CTA", x: 792, y: 460, width: 260, height: 24, size: 13, z: z + 20),
            text("bottom nav", x: 792, y: 492, width: 260, height: 24, size: 13, z: z + 21),
        ]
        return out
    }

    private static func swotElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("SWOT", x: 230, y: 122, width: 180, height: 48, size: 34, bold: true, z: z),
            text("Use case label: launch-readiness reality check", x: 230, y: 174, width: 420, height: 24, size: 15, z: z + 1),
        ]
        z += 2

        let boxes: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, bullets: String)] = [
            ("Strengths", 220, 220, .mint, "• Fast board rendering\n• Intuitive templates\n• Lightweight onboarding\n• Clear visual hierarchy\n• Strong solo-user fit"),
            ("Weaknesses", 760, 220, .blush, "• Limited collaboration depth\n• Export options are basic\n• Connector edits still tricky\n• Sparse integrations\n• Mobile workflow is rough"),
            ("Opportunities", 220, 560, .sky, "• Async planning trend\n• Creator partnership channels\n• Template marketplace potential\n• Education segment pull\n• AI-assisted organization"),
            ("Threats", 760, 560, .lavender, "• Bundled suite competition\n• Pricing pressure in SMB\n• Reliability incidents hurt trust\n• Fast-moving AI alternatives\n• Feature fatigue risk"),
        ]

        for box in boxes {
            out.append(shape(kind: .roundedRectangle, x: box.x, y: box.y, width: 500, height: 300, stroke: shapeStroke, fill: tint(box.color.rgba, alpha: 0.16), z: z))
            out.append(text(box.title, x: box.x + 20, y: box.y + 20, width: 460, height: 30, size: 22, bold: true, z: z + 1))
            out.append(text(box.bullets, x: box.x + 20, y: box.y + 68, width: 460, height: 206, size: 14, z: z + 2))
            z += 3
        }
        out += [
            text("Top question this week:", x: 1230, y: 150, width: 160, height: 22, size: 12, bold: true, z: z),
            text("Can we launch without hurting trust?", x: 1170, y: 174, width: 220, height: 22, size: 12, z: z + 1),
            text("Risk owner: PM + Eng", x: 1218, y: 198, width: 172, height: 20, size: 11.5, z: z + 2),
            text("Next checkpoint: Friday", x: 1210, y: 220, width: 180, height: 20, size: 11.5, z: z + 3),
            text("Confidence: medium-low", x: 1214, y: 242, width: 176, height: 20, size: 11.5, z: z + 4),
        ]
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
        z: Int,
        cornerRadius: Double = 16
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
                cornerRadius: cornerRadius
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
