/// Barrel de DIALOGS do design system — ponto único de import para abrir
/// os overlays padrão da app: bottom sheets ([showAppSheet]), dialogs de
/// confirmação ([showConfirmDialog]) / entrada ([showInputDialog]) e o
/// snackbar com undo ([showUndoSnackBar]).
///
/// Componentes de layout de sheet (`SheetSection`, `SheetHeader`,
/// `AppSheetHeader`) continuam em `app_sheet.dart` e importam-se à parte.
library;

export 'app_sheet.dart' show showAppSheet;
export 'confirm_dialog.dart' show showConfirmDialog;
export 'snackbar_with_undo.dart' show showUndoSnackBar;
export 'input_dialog.dart' show showInputDialog;
