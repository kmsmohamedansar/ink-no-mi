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
            text("Q3 Launch Brainstorm Sprint", x: 220, y: 112, width: 620, height: 50, size: 34, bold: true, z: z),
            text("Cross-functional workshop board for week-one launch planning", x: 222, y: 166, width: 620, height: 24, size: 15, z: z + 1),
        ]
        z += 2

        let clusters: [(title: String, color: StickyNoteColorPreset, x: Double, y: Double, notes: [String])] = [
            ("Ideas", .mint, 220, 220, [
                "Host a 30-min launch livestream with live Q&A and board demo",
                "Bundle top 3 templates as a downloadable kickoff pack",
                "Publish short founder videos showing real planning workflows",
                "Offer a concierge setup call for first 20 paid teams",
                "Add a launch countdown checklist directly in onboarding",
            ]),
            ("Problems", .blush, 620, 220, [
                "Users still ask where to start when opening a blank board",
                "Template copy feels generic and not tied to real workflows",
                "Launch assets live in three folders and go out of sync",
                "No single owner for day-of support triage coverage",
                "Roadmap board gets stale because updates are ad-hoc",
            ]),
            ("Opportunities", .sky, 220, 560, [
                "Turn strong customer examples into reusable premium template packs",
                "Add role-based starter kits for PM, founder, and design teams",
                "Create onboarding prompts tied to each template category",
                "Partner with two agencies for co-branded launch playbooks",
                "Use milestone reminders to re-engage dormant trial users",
            ]),
            ("Next experiments", .lemon, 620, 560, [
                "Run 5 moderated sessions with new users on template gallery",
                "A/B test concise vs narrative onboarding hints for first board",
                "Pilot weekly digest email with one guided board prompt",
                "Ship one 'premium-ready' template set and track activation lift",
                "Time-box a launch war-room simulation with support and eng",
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
            text("Enterprise Demo Qualification Flow", x: 400, y: 110, width: 560, height: 48, size: 34, bold: true, z: 10, alignment: .center),
            text("Sales + solutions handoff flow with branch decisions", x: 422, y: 162, width: 520, height: 24, size: 15, z: 11, alignment: .center),
            text("Decision branch labels are on connectors", x: 530, y: 194, width: 310, height: 20, size: 12, z: 12, alignment: .center),
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
            text("Product Roadmap - H2 2026", x: 220, y: 108, width: 560, height: 48, size: 34, bold: true, z: z),
            text("Planning board with ownership, priorities, and timeline checkpoints", x: 222, y: 160, width: 700, height: 24, size: 15, z: z + 1),
        ]
        z += 2

        out += [
            text("Jul", x: 254, y: 194, width: 60, height: 20, size: 12, bold: true, z: z),
            text("Aug", x: 624, y: 194, width: 60, height: 20, size: 12, bold: true, z: z + 1),
            text("Sep", x: 994, y: 194, width: 60, height: 20, size: 12, bold: true, z: z + 2),
            text("Oct+", x: 1364, y: 194, width: 60, height: 20, size: 12, bold: true, z: z + 3),
        ]
        z += 4

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, items: [(work: String, owner: String, priority: String)])] = [
            ("Now", .mint, 220, [
                ("Stabilize offline sync on boards with 1K+ elements", "Owner: Ramon", "P0"),
                ("Refresh template gallery with customer-like examples", "Owner: Elise", "P1"),
                ("Improve PDF export spacing and text wrapping", "Owner: Jun", "P1"),
                ("Tighten onboarding first-run hints", "Owner: Priya", "P1"),
                ("Fix duplicate board title race condition", "Owner: Mei", "P2"),
            ]),
            ("Next", .sky, 590, [
                ("Ship lightweight board comments for async reviews", "Owner: Omar", "P1"),
                ("Add reusable visual style presets v1", "Owner: Elise", "P2"),
                ("Publish milestone dashboard alpha", "Owner: Priya", "P1"),
                ("Run large-board performance optimization pass", "Owner: Ramon", "P0"),
                ("Improve template recommendation ranking", "Owner: Jun", "P2"),
            ]),
            ("Later", .lavender, 960, [
                ("AI assist for organizing unstructured brainstorm boards", "Owner: Mei", "P2"),
                ("Enable cross-board linking and previews", "Owner: Omar", "P2"),
                ("Launch team-curated template packs", "Owner: Elise", "P2"),
                ("Roll out privacy-safe usage insights", "Owner: Priya", "P3"),
                ("Prototype lightweight mobile companion", "Owner: Jun", "P3"),
            ]),
            ("Parking Lot", .lemon, 1330, [
                ("In-app chat for board collaborators", "Owner: TBD", "P3"),
                ("Template marketplace revenue share model", "Owner: TBD", "P3"),
                ("White-label branding controls", "Owner: TBD", "P3"),
                ("Advanced workflow automations", "Owner: TBD", "P3"),
                ("Native desktop widgets experiment", "Owner: TBD", "P3"),
            ]),
        ]

        for column in columns {
            out.append(shape(kind: .roundedRectangle, x: column.x - 10, y: 230, width: 320, height: 520, stroke: shapeStroke, fill: tint(column.color.rgba, alpha: 0.16), z: z))
            out.append(text(column.title, x: column.x + 10, y: 250, width: 300, height: 32, size: 24, bold: true, z: z + 1, alignment: .center))
            z += 2

            var y = 300.0
            for (index, item) in column.items.enumerated() {
                let h = 68.0 + Double((index % 3) * 8)
                out.append(note(item.work, x: column.x + 6, y: y, width: 282, height: h, color: column.color, z: z))
                let pillColor: StickyNoteColorPreset = item.priority == "P0" ? .blush : (item.priority == "P1" ? .sky : .lemon)
                out.append(shape(kind: .roundedRectangle, x: column.x + 214, y: y + 8, width: 66, height: 24, stroke: shapeStroke, fill: tint(pillColor.rgba, alpha: 0.32), z: z + 1, cornerRadius: 12))
                out.append(text(item.priority, x: column.x + 224, y: y + 12, width: 46, height: 16, size: 11.5, bold: true, z: z + 2, alignment: .center))
                out.append(text(item.owner, x: column.x + 18, y: y + h - 22, width: 190, height: 16, size: 11.5, z: z + 3))
                z += 1
                y += h + 12
            }
        }
        return out
    }

    private static func meetingNotesElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Weekly Product Sync - Meeting Notes", x: 224, y: 112, width: 610, height: 48, size: 34, bold: true, z: z),
            text("Apr 24, 2026 - Release readiness and launch owners", x: 226, y: 164, width: 520, height: 24, size: 15, z: z + 1),
            shape(kind: .roundedRectangle, x: 220, y: 220, width: 360, height: 620, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.13), z: z + 1),
            shape(kind: .roundedRectangle, x: 610, y: 220, width: 360, height: 620, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.12), z: z + 2),
            shape(kind: .roundedRectangle, x: 1000, y: 220, width: 360, height: 620, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.12), z: z + 3),
        ]
        z += 4
        out += [
            text("Meeting details", x: 248, y: 246, width: 320, height: 30, size: 20, bold: true, z: z),
            text("Date: Fri 10:00 - 10:45", x: 250, y: 286, width: 220, height: 24, size: 13, z: z + 1),
            text("Host: Priya", x: 250, y: 314, width: 170, height: 24, size: 13, z: z + 2),
            text("Attendees: Priya, Ramon, Elise, Jun, Mei", x: 250, y: 342, width: 318, height: 24, size: 13, z: z + 3),
            text("Agenda", x: 248, y: 382, width: 320, height: 30, size: 20, bold: true, z: z + 4),
            note("Release status and top two launch blockers", x: 250, y: 424, width: 292, height: 62, color: .lemon, z: z + 5),
            note("Template quality pass and screenshot readiness", x: 252, y: 496, width: 286, height: 58, color: .lemon, z: z + 6),
            note("Decide launch freeze date and owner handoff", x: 252, y: 564, width: 286, height: 58, color: .lemon, z: z + 7),
            text("Notes", x: 640, y: 246, width: 300, height: 30, size: 20, bold: true, z: z + 8),
            note("Beta users liked speed, still confused by connector handles.", x: 638, y: 288, width: 300, height: 90, color: .sky, z: z + 9),
            note("Onboarding copy sounds too polished; make it more human.", x: 636, y: 388, width: 304, height: 86, color: .sky, z: z + 10),
            note("Need one owner for perf budget and weekly check.", x: 640, y: 484, width: 298, height: 84, color: .sky, z: z + 11),
            text("Decisions", x: 640, y: 584, width: 300, height: 30, size: 20, bold: true, z: z + 12),
            note("Ship template refresh in this sprint, not next.", x: 638, y: 624, width: 300, height: 78, color: .sky, z: z + 13),
            note("Defer markdown export polish by one release.", x: 640, y: 710, width: 296, height: 76, color: .sky, z: z + 14),
            text("Action items", x: 1030, y: 246, width: 300, height: 30, size: 20, bold: true, z: z + 15),
            note("Ramon - Fix connector snapping | Due: Apr 29", x: 1030, y: 288, width: 300, height: 72, color: .mint, z: z + 16),
            note("Elise - Rewrite 8 template notes | Due: Apr 30", x: 1030, y: 368, width: 302, height: 84, color: .mint, z: z + 17),
            note("Jun - Verify iPhone SE clipping | Due: Apr 28", x: 1032, y: 460, width: 296, height: 72, color: .mint, z: z + 18),
            note("Priya - Publish launch checklist v3 | Due: May 1", x: 1032, y: 540, width: 296, height: 76, color: .mint, z: z + 19),
            note("All - Add one blocker before tomorrow's standup", x: 1030, y: 624, width: 302, height: 78, color: .mint, z: z + 20),
        ]
        return out
    }

    private static func mindMapElements() -> [CanvasElementRecord] {
        var out: [CanvasElementRecord] = [
            text("Launch Strategy Mind Map", x: 230, y: 108, width: 440, height: 48, size: 34, bold: true, z: 7),
            text("One-page view of key levers, bets, and risks", x: 232, y: 160, width: 430, height: 24, size: 15, z: 8),
        ]

        let centerID = UUID()
        out.append(shape(id: centerID, kind: .ellipse, x: 720, y: 430, width: 200, height: 94, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.28), z: 19))
        out.append(text("Launch Plan", x: 744, y: 462, width: 152, height: 24, size: 20, bold: true, z: 20, alignment: .center))

        let branches: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, subs: [String])] = [
            ("Users", 450, 260, .mint, ["Solo creators", "Startup PM teams", "Ops-heavy agencies"]),
            ("Product", 980, 300, .sky, ["Template realism", "Fast connector editing", "Smooth onboarding"]),
            ("Revenue", 1020, 600, .lemon, ["Pro monthly plan", "Team annual contracts", "Export add-on upsell"]),
            ("Marketing", 520, 650, .blush, ["Founder-led videos", "Partner launches", "Referral loops"]),
            ("Risks", 240, 520, .lavender, ["Stability regressions", "Slow team features", "Pricing confusion"]),
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
            text("Launch Operations Kanban", x: 224, y: 108, width: 450, height: 48, size: 34, bold: true, z: z),
            text("Weekly execution board with status, tags, and priority chips", x: 226, y: 160, width: 620, height: 24, size: 15, z: z + 1),
        ]
        z += 2

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, cards: [(task: String, tag: String, priority: String)])] = [
            ("Backlog", .lemon, 220, [
                ("Finalize launch FAQ with last two legal answers", "Docs", "P2"),
                ("Review accessibility contrast token usage", "Design", "P1"),
                ("Set up beta feedback board taxonomy", "Ops", "P2"),
                ("Write release announcement first draft", "Marketing", "P1"),
                ("Audit analytics event naming consistency", "Data", "P2"),
            ]),
            ("In Progress", .sky, 520, [
                ("Template realism copy pass across 8 seeds", "Content", "P0"),
                ("Improve connector hit-testing precision", "iOS", "P0"),
                ("Benchmark rendering on 1K-element boards", "Perf", "P1"),
                ("Prepare support macro snippets for launch week", "Support", "P1"),
                ("Rewrite empty-state hints to reduce confusion", "UX", "P1"),
            ]),
            ("Review", .lavender, 820, [
                ("Board creation flow QA checklist signoff", "QA", "P1"),
                ("Import/export edge-case file verification", "QA", "P2"),
                ("Flowchart seed spacing tune-up", "Design", "P2"),
                ("Meeting notes seed wording pass", "Content", "P2"),
                ("Smoke test on iPad split view", "iOS", "P1"),
            ]),
            ("Done", .mint, 1120, [
                ("Migrate board payload serialization to v1", "Core", "P0"),
                ("Refactor canvas undo grouping behavior", "Core", "P1"),
                ("Align empty-state copy across home screens", "Content", "P2"),
                ("Fix missing icon in sidebar navigation", "UI", "P2"),
                ("Stabilize template thumbnail generation", "Infra", "P1"),
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
                out.append(note(card.task, x: column.x + Double((index % 2) * 4), y: y, width: w, height: h, color: column.color, z: z))
                let chipColor: StickyNoteColorPreset = card.priority == "P0" ? .blush : (card.priority == "P1" ? .sky : .lemon)
                out.append(shape(kind: .roundedRectangle, x: column.x + 182, y: y + 8, width: 54, height: 22, stroke: shapeStroke, fill: tint(chipColor.rgba, alpha: 0.3), z: z + 1, cornerRadius: 11))
                out.append(text(card.priority, x: column.x + 194, y: y + 11, width: 30, height: 16, size: 11, bold: true, z: z + 2, alignment: .center))
                out.append(text(card.tag, x: column.x + 16, y: y + h - 22, width: 150, height: 16, size: 11.5, bold: true, z: z + 3))
                z += 1
                y += h + 12
            }
        }
        return out
    }

    private static func wireframeElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("App Wireframe - Mobile Home", x: 220, y: 108, width: 520, height: 48, size: 34, bold: true, z: z),
            text("High-fidelity layout sketch with implementation notes", x: 222, y: 160, width: 500, height: 24, size: 15, z: z + 1),
        ]
        z += 2

        out += [
            shape(kind: .roundedRectangle, x: 280, y: 220, width: 360, height: 690, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.97, green: 0.97, blue: 0.98, opacity: 1), z: z, cornerRadius: 42),
            shape(kind: .roundedRectangle, x: 306, y: 250, width: 308, height: 30, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.1), z: z + 1, cornerRadius: 10),
            text("Status bar", x: 420, y: 258, width: 80, height: 16, size: 11, z: z + 2, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 292, width: 308, height: 72, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.16), z: z + 3),
            text("Header - Good morning, Maya", x: 360, y: 320, width: 200, height: 20, size: 13.5, bold: true, z: z + 4, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 378, width: 308, height: 160, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lavender.rgba, alpha: 0.16), z: z + 5),
            text("Hero - This week's launch checklist", x: 346, y: 448, width: 228, height: 24, size: 13, bold: true, z: z + 6, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 552, width: 308, height: 180, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.14), z: z + 7),
            text("Content cards", x: 404, y: 632, width: 112, height: 20, size: 13, bold: true, z: z + 8, alignment: .center),
            shape(kind: .roundedRectangle, x: 324, y: 572, width: 272, height: 42, stroke: shapeStroke, fill: CanvasRGBAColor(red: 1, green: 1, blue: 1, opacity: 0.7), z: z + 9),
            text("Card: Sprint health at 78%", x: 340, y: 586, width: 236, height: 18, size: 12, z: z + 10),
            shape(kind: .roundedRectangle, x: 324, y: 622, width: 272, height: 42, stroke: shapeStroke, fill: CanvasRGBAColor(red: 1, green: 1, blue: 1, opacity: 0.7), z: z + 11),
            text("Card: 3 blockers need owner", x: 342, y: 636, width: 236, height: 18, size: 12, z: z + 12),
            shape(kind: .roundedRectangle, x: 324, y: 672, width: 272, height: 42, stroke: shapeStroke, fill: CanvasRGBAColor(red: 1, green: 1, blue: 1, opacity: 0.7), z: z + 13),
            text("Card: Team update due 5PM", x: 342, y: 686, width: 236, height: 18, size: 12, z: z + 14),
            shape(kind: .roundedRectangle, x: 306, y: 742, width: 308, height: 58, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.2), z: z + 9),
            text("CTA - Start today's focus board", x: 358, y: 762, width: 206, height: 20, size: 13, bold: true, z: z + 10, alignment: .center),
            shape(kind: .roundedRectangle, x: 306, y: 810, width: 308, height: 74, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.12), z: z + 11),
            text("Bottom nav - Home | Boards | Search | Profile", x: 336, y: 838, width: 246, height: 20, size: 12.5, z: z + 12, alignment: .center),
        ]

        out += [
            shape(kind: .roundedRectangle, x: 760, y: 230, width: 560, height: 420, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.blush.rgba, alpha: 0.1), z: z + 13),
            text("Annotation notes", x: 790, y: 258, width: 220, height: 24, size: 16, bold: true, z: z + 14),
            note("Phone frame uses 16pt safe side padding.", x: 792, y: 294, width: 246, height: 56, color: .blush, z: z + 15),
            note("Header must show user context + streak icon.", x: 792, y: 360, width: 246, height: 56, color: .blush, z: z + 16),
            note("Hero rotates between launch, risk, and review prompts.", x: 792, y: 426, width: 246, height: 66, color: .blush, z: z + 17),
            note("Cards stay tappable with 44pt minimum touch targets.", x: 1054, y: 294, width: 246, height: 62, color: .blush, z: z + 18),
            note("CTA appears only when no urgent blockers exist.", x: 1054, y: 366, width: 246, height: 56, color: .blush, z: z + 19),
            note("Bottom nav keeps current tab highlighted for orientation.", x: 1054, y: 432, width: 246, height: 60, color: .blush, z: z + 20),
        ]
        return out
    }

    private static func swotElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("SWOT Analysis - Launch Readiness", x: 224, y: 108, width: 560, height: 48, size: 34, bold: true, z: z),
            text("Quarterly strategy review with concrete strengths, gaps, and risks", x: 226, y: 160, width: 640, height: 24, size: 15, z: z + 1),
        ]
        z += 2

        let boxes: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, bullets: [String])] = [
            ("Strengths", 220, 220, .mint, ["Fast board rendering on large canvases", "Template set covers common team workflows", "Low-friction onboarding for solo users", "Visual hierarchy reads clearly in screenshots", "Internal shipping cadence is reliable"]),
            ("Weaknesses", 760, 220, .blush, ["Collaboration depth is still lightweight", "Export options lag power-user needs", "Connector edits remain error-prone", "Integration catalog is very small", "Mobile workflow feels cramped for planning"]),
            ("Opportunities", 220, 560, .sky, ["Async planning trend keeps growing in SMB", "Partner channels can widen top-of-funnel reach", "Premium template packs can drive paid upgrades", "Education segment asks for planning workflows", "AI assist can accelerate board organization"]),
            ("Threats", 760, 560, .lavender, ["Bundled suites undercut standalone pricing", "SMB budget pressure slows conversions", "Reliability incidents can hurt trust quickly", "AI-native competitors iterate aggressively", "Feature sprawl can weaken product clarity"]),
        ]

        for box in boxes {
            out.append(shape(kind: .roundedRectangle, x: box.x, y: box.y, width: 500, height: 300, stroke: shapeStroke, fill: tint(box.color.rgba, alpha: 0.16), z: z))
            out.append(text(box.title, x: box.x + 20, y: box.y + 20, width: 460, height: 30, size: 22, bold: true, z: z + 1))
            var bulletY = box.y + 66
            for bullet in box.bullets {
                out.append(text("• \(bullet)", x: box.x + 22, y: bulletY, width: 456, height: 30, size: 13.5, z: z + 2))
                bulletY += 44
            }
            z += 7
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
