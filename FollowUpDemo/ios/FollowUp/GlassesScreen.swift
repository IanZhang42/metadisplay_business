import MWDATDisplay

struct GlassesAction: Sendable { let id: String; let label: String }
enum GlassesScreen {
  static func make(title: String, detail: String, footer: String, actions: [GlassesAction],
    onAction: @escaping @Sendable (String) -> Void) -> FlexBox {
    FlexBox(direction: .column, spacing: 12) {
      Text(title, style: .heading)
      Text(detail, style: .body)
      Text(footer, style: .meta, color: .secondary)
      ButtonGroup {
        for index in actions.indices {
          if index == 0 {
            Button(label: actions[index].label, onClick: { onAction(actions[index].id) }).actionRole(.primary)
          } else {
            Button(label: actions[index].label, onClick: { onAction(actions[index].id) })
          }
        }
      }
    }.padding(24).background(.card)
  }
}
