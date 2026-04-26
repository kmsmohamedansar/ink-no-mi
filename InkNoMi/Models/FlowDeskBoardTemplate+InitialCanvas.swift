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
            text("Product Launch Brainstorm", x: 260, y: 36, width: 560, height: 44, size: 30, bold: true, z: z),
            text("Use clusters to map ideas before prioritizing.", x: 260, y: 84, width: 560, height: 24, size: 14, z: z + 1),
        ]
        z += 2

        let clusters: [(title: String, color: StickyNoteColorPreset, x: Double, y: Double, notes: [String])] = [
            ("Growth Channels", .mint, 70, 150, [
                "Partner with 3 creator communities",
                "Run launch-week referral challenge",
                "Ship feature teaser clips on social",
                "Publish comparison page with ROI examples",
                "Offer onboarding webinar series",
            ]),
            ("User Pain Points", .blush, 510, 150, [
                "First setup feels overwhelming",
                "Unclear difference between board types",
                "No guidance after blank board opens",
                "Hard to find recently edited work",
                "Template previews look too generic",
            ]),
            ("Retention Ideas", .sky, 950, 150, [
                "Weekly planning reminder nudges",
                "Milestone celebration for project progress",
                "Starter kits per role and workflow",
                "Team handoff checklist template",
                "Monthly recap board auto-generated",
            ]),
        ]

        for cluster in clusters {
            out.append(shape(kind: .roundedRectangle, x: cluster.x - 26, y: cluster.y - 26, width: 388, height: 404, stroke: shapeStroke, fill: tint(cluster.color.rgba, alpha: 0.18), z: z))
            out.append(text(cluster.title, x: cluster.x - 8, y: cluster.y - 8, width: 320, height: 28, size: 18, bold: true, z: z + 1))
            z += 2
            var noteY = cluster.y + 34
            for line in cluster.notes {
                out.append(note(line, x: cluster.x, y: noteY, width: 332, height: 58, color: cluster.color, z: z))
                z += 1
                noteY += 66
            }
        }
        return out
    }

    private static func flowchartElements() -> [CanvasElementRecord] {
        var out: [CanvasElementRecord] = [
            text("Lead Qualification Flow", x: 320, y: 44, width: 460, height: 40, size: 28, bold: true, z: 10),
            text("Standard intake sequence with decision points and clear outcomes.", x: 320, y: 86, width: 460, height: 24, size: 14, z: 11),
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
            text("Start: New inbound lead", x: 472, y: 165, width: 156, height: 24, size: 14, bold: true, z: 21, alignment: .center),

            shape(id: intakeID, kind: .roundedRectangle, x: 450, y: 250, width: 200, height: 80, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 22),
            text("Collect context\n(company, role, use case)", x: 468, y: 272, width: 164, height: 48, size: 13, z: 23, alignment: .center),

            shape(id: fitID, kind: .roundedRectangle, x: 430, y: 370, width: 240, height: 90, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lavender.rgba, alpha: 0.22), z: 24),
            text("Decision: Is the use case a strong fit?", x: 444, y: 402, width: 212, height: 28, size: 14, bold: true, z: 25, alignment: .center),

            shape(id: demoID, kind: .roundedRectangle, x: 740, y: 500, width: 220, height: 84, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.18), z: 26),
            text("Schedule demo\nwithin 48 hours", x: 770, y: 526, width: 160, height: 44, size: 13, z: 27, alignment: .center),

            shape(id: nurtureID, kind: .roundedRectangle, x: 140, y: 500, width: 240, height: 84, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.blush.rgba, alpha: 0.2), z: 28),
            text("Add to nurture path\nand send resources", x: 172, y: 526, width: 176, height: 44, size: 13, z: 29, alignment: .center),

            shape(id: proposalID, kind: .roundedRectangle, x: 740, y: 640, width: 220, height: 84, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.2), z: 30),
            text("Send proposal\nand timeline", x: 776, y: 666, width: 148, height: 44, size: 13, z: 31, alignment: .center),

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
        ]
        return out
    }

    private static func roadmapElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Product Roadmap", x: 170, y: 42, width: 840, height: 40, size: 30, bold: true, z: z),
            text("Now / Next / Later priorities aligned around reliability and growth.", x: 170, y: 84, width: 840, height: 24, size: 14, z: z + 1),
        ]
        z += 2

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, items: [String])] = [
            ("Now", .mint, 80, [
                "Stabilize offline editing sync",
                "Launch revamped template gallery",
                "Improve export quality for PDF",
                "Refine onboarding empty states",
            ]),
            ("Next", .sky, 470, [
                "Add board-level collaboration comments",
                "Ship reusable style presets",
                "Introduce milestone dashboard",
                "Optimize large board performance",
            ]),
            ("Later", .lavender, 860, [
                "AI-assisted content organization",
                "Cross-board linking system",
                "Shared team template packs",
                "Usage analytics and insights",
            ]),
        ]

        for column in columns {
            out.append(shape(kind: .roundedRectangle, x: column.x - 24, y: 142, width: 340, height: 510, stroke: shapeStroke, fill: tint(column.color.rgba, alpha: 0.16), z: z))
            out.append(text(column.title, x: column.x, y: 166, width: 292, height: 30, size: 24, bold: true, z: z + 1))
            z += 2

            var y = 220.0
            for item in column.items {
                out.append(note(item, x: column.x, y: y, width: 292, height: 84, color: column.color, z: z))
                z += 1
                y += 98
            }
        }
        return out
    }

    private static func meetingNotesElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            shape(kind: .roundedRectangle, x: 100, y: 46, width: 1100, height: 800, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.96, green: 0.97, blue: 0.99, opacity: 0.95), z: z),
            text("Weekly Product Sync", x: 132, y: 78, width: 620, height: 40, size: 30, bold: true, z: z + 1),
            text("Date: Tuesday, 10:00 AM  •  Facilitator: Maya  •  Attendees: Product, Design, Engineering", x: 132, y: 122, width: 920, height: 24, size: 13, z: z + 2),
        ]
        z += 3

        let sections: [(title: String, x: Double, y: Double, width: Double, body: String)] = [
            ("Agenda", 132, 176, 496, "1. Release status review\n2. Customer feedback themes\n3. Risks and dependencies\n4. Decisions needed this week"),
            ("Discussion Notes", 132, 356, 496, "• Beta users praised faster loading on large boards.\n• Confusion remains around inserting connectors from toolbar.\n• Team agreed to tighten template copy before launch.\n• Performance benchmark target set to <120ms interaction latency."),
            ("Action Items", 662, 176, 496, "• Priya: draft updated onboarding script by Thursday.\n• Ramon: ship connector snapping fix in next sprint.\n• Elise: prepare launch checklist and risk log update.\n• Team: validate template quality with 5 internal users."),
            ("Parking Lot", 662, 470, 496, "• Should comments be board-level or element-level first?\n• Decide whether to prioritize markdown export.\n• Explore reusable component library for template cards."),
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
            text("Q3 Launch Strategy", x: 500, y: 388, width: 220, height: 44, size: 22, bold: true, z: 20, alignment: .center),
        ]

        let centerID = UUID()
        out.append(shape(id: centerID, kind: .ellipse, x: 470, y: 360, width: 280, height: 108, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.28), z: 19))

        let branches: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, subs: [String])] = [
            ("Messaging", 190, 210, .blush, ["Value proposition", "Proof points"]),
            ("Channels", 870, 210, .mint, ["Owned email", "Partner co-marketing"]),
            ("Sales Enablement", 900, 520, .sky, ["Demo script", "Objection handling"]),
            ("Launch Ops", 180, 540, .lavender, ["Timeline owner", "Readiness checklist"]),
            ("Customer Success", 500, 640, .mint, ["Onboarding touchpoints", "Success metrics"]),
        ]

        var z = 30
        for branch in branches {
            let branchID = UUID()
            out.append(shape(id: branchID, kind: .roundedRectangle, x: branch.x, y: branch.y, width: 230, height: 82, stroke: shapeStroke, fill: tint(branch.color.rgba, alpha: 0.22), z: z))
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
            text("Sprint Kanban Board", x: 130, y: 40, width: 960, height: 42, size: 30, bold: true, z: z),
            text("Drag cards across columns as work progresses.", x: 130, y: 84, width: 960, height: 24, size: 14, z: z + 1),
        ]
        z += 2

        let columns: [(title: String, color: StickyNoteColorPreset, x: Double, cards: [String])] = [
            ("To Do", .lemon, 90, [
                "Finalize launch FAQ content",
                "Review accessibility contrast tokens",
                "Set up customer beta feedback board",
                "Write release announcement draft",
            ]),
            ("In Progress", .sky, 480, [
                "Template layout polish pass",
                "Improve connector hit-testing precision",
                "Benchmark rendering on large boards",
            ]),
            ("Done", .mint, 870, [
                "Migrate board payload to format v1",
                "Refactor canvas undo grouping",
                "Align empty-state copy across home",
            ]),
        ]

        for column in columns {
            out.append(shape(kind: .roundedRectangle, x: column.x - 20, y: 140, width: 330, height: 620, stroke: shapeStroke, fill: tint(column.color.rgba, alpha: 0.15), z: z))
            out.append(text(column.title, x: column.x, y: 168, width: 290, height: 30, size: 22, bold: true, z: z + 1))
            z += 2

            var y = 226.0
            for card in column.cards {
                out.append(note(card, x: column.x, y: y, width: 290, height: 96, color: column.color, z: z))
                z += 1
                y += 112
            }
        }
        return out
    }

    private static func wireframeElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("Mobile App Wireframe", x: 222, y: 42, width: 520, height: 42, size: 30, bold: true, z: z),
            text("Low-fidelity layout for a productivity home screen.", x: 222, y: 84, width: 520, height: 24, size: 14, z: z + 1),
        ]
        z += 2

        out += [
            shape(kind: .roundedRectangle, x: 240, y: 130, width: 390, height: 760, stroke: shapeStroke, fill: CanvasRGBAColor(red: 0.97, green: 0.97, blue: 0.98, opacity: 1), z: z),
            text("App Header", x: 270, y: 156, width: 330, height: 28, size: 16, bold: true, z: z + 1, alignment: .center),
            shape(kind: .roundedRectangle, x: 270, y: 198, width: 330, height: 64, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.sky.rgba, alpha: 0.14), z: z + 2),
            text("Search Bar", x: 286, y: 220, width: 298, height: 24, size: 13, z: z + 3),
            shape(kind: .roundedRectangle, x: 270, y: 286, width: 330, height: 176, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lavender.rgba, alpha: 0.14), z: z + 4),
            text("Hero Card", x: 286, y: 364, width: 298, height: 24, size: 14, bold: true, z: z + 5, alignment: .center),
            shape(kind: .roundedRectangle, x: 270, y: 484, width: 160, height: 150, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.14), z: z + 6),
            shape(kind: .roundedRectangle, x: 440, y: 484, width: 160, height: 150, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.mint.rgba, alpha: 0.14), z: z + 7),
            text("Card A", x: 318, y: 548, width: 64, height: 22, size: 12, bold: true, z: z + 8, alignment: .center),
            text("Card B", x: 488, y: 548, width: 64, height: 22, size: 12, bold: true, z: z + 9, alignment: .center),
            shape(kind: .roundedRectangle, x: 270, y: 658, width: 330, height: 136, stroke: shapeStroke, fill: tint(StickyNoteColorPreset.lemon.rgba, alpha: 0.14), z: z + 10),
            text("Bottom Navigation", x: 286, y: 714, width: 298, height: 24, size: 13, z: z + 11, alignment: .center),
        ]

        out += [
            text("1) Keep spacing in 8pt increments", x: 700, y: 250, width: 360, height: 24, size: 13, z: z + 12),
            text("2) Prioritize primary action above fold", x: 700, y: 286, width: 360, height: 24, size: 13, z: z + 13),
            text("3) Validate readability at 13pt text", x: 700, y: 322, width: 360, height: 24, size: 13, z: z + 14),
        ]
        return out
    }

    private static func swotElements() -> [CanvasElementRecord] {
        var z = 10
        var out: [CanvasElementRecord] = [
            text("SWOT Analysis - Productivity App Launch", x: 180, y: 36, width: 820, height: 42, size: 30, bold: true, z: z),
            text("Capture internal and external factors before final go-to-market planning.", x: 180, y: 80, width: 820, height: 24, size: 14, z: z + 1),
        ]
        z += 2

        let boxes: [(title: String, x: Double, y: Double, color: StickyNoteColorPreset, bullets: String)] = [
            ("Strengths", 120, 150, .mint, "• Fast visual canvas interactions\n• Clear minimalist interface\n• Strong template-based onboarding"),
            ("Weaknesses", 640, 150, .blush, "• Collaboration features still limited\n• Missing advanced export controls\n• Learning curve for connector editing"),
            ("Opportunities", 120, 470, .sky, "• Growing demand for async planning tools\n• Teams moving from static docs to canvases\n• Channel partnerships with design communities"),
            ("Threats", 640, 470, .lavender, "• Strong incumbents with deeper ecosystems\n• Price pressure from bundled suites\n• User churn if reliability regresses"),
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
