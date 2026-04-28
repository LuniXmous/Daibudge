import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../models/transaction_model.dart';



class GoogleSheetsService {
  static final GoogleSheetsService instance = GoogleSheetsService._internal();

  factory GoogleSheetsService() => instance;

  GoogleSheetsService._internal();

  static const String templateSpreadsheetId =
      '10w_z3HkK9xxvdH2P258GVLKe8gQCDiv6DBxEPSxk4BE';
  static const String sheetName = "'DAILY TRACKING'";
  static const String activeSpreadsheetIdKey = 'active_spreadsheet_id';

  Future<drive.DriveApi?> getDriveApi() async {
    currentUser ??= await _googleSignIn.signInSilently();

    if (currentUser == null) {
      currentUser = await _googleSignIn.signIn();
    }

    if (currentUser == null) return null;

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;

    return drive.DriveApi(client);
  }

  Future<void> saveActiveSpreadsheetId(String spreadsheetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(activeSpreadsheetIdKey, spreadsheetId);
  }

  Future<String?> getActiveSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(activeSpreadsheetIdKey);
  }

  Future<int?> getSheetIdByName(
    SheetsApi sheetsApi,
    String spreadsheetId,
    String title,
  ) async {
    final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);

    final sheets = spreadsheet.sheets ?? [];

    for (final sheet in sheets) {
      if (sheet.properties?.title == title) {
        return sheet.properties?.sheetId;
      }
    }

    return null;
  }
  
  Future<void> applySpreadsheetStyle(String spreadsheetId) async {
    final sheetsApi = await getSheetsApi();
    if (sheetsApi == null) return;

    const cleanSheetName = 'DAILY TRACKING';
    final sheetId = await getSheetIdByName(
      sheetsApi,
      spreadsheetId,
      cleanSheetName,
    );

    if (sheetId == null) return;

    final request = BatchUpdateSpreadsheetRequest(
      requests: [
        // Header row 6: A6:I6 bold + center
        Request(
          repeatCell: RepeatCellRequest(
            range: GridRange(
              sheetId: sheetId,
              startRowIndex: 5,
              endRowIndex: 6,
              startColumnIndex: 0,
              endColumnIndex: 11,
            ),
            cell: CellData(
              userEnteredFormat: CellFormat(
                textFormat: TextFormat(bold: true),
                horizontalAlignment: 'CENTER',
                verticalAlignment: 'MIDDLE',
              ),
            ),
            fields:
                'userEnteredFormat.textFormat.bold,userEnteredFormat.horizontalAlignment,userEnteredFormat.verticalAlignment',
          ),
        ),

        // Kolom C Nominal: Rupiah
        Request(
          repeatCell: RepeatCellRequest(
            range: GridRange(
              sheetId: sheetId,
              startRowIndex: 6,
              startColumnIndex: 2,
              endColumnIndex: 3,
            ),
            cell: CellData(
              userEnteredFormat: CellFormat(
                numberFormat: NumberFormat(
                  type: 'CURRENCY',
                  pattern: '"Rp"#,##0',
                ),
              ),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),

        // Kolom D Biaya Admin: Rupiah / angka
        Request(
          repeatCell: RepeatCellRequest(
            range: GridRange(
              sheetId: sheetId,
              startRowIndex: 6,
              startColumnIndex: 3,
              endColumnIndex: 4,
            ),
            cell: CellData(
              userEnteredFormat: CellFormat(
                numberFormat: NumberFormat(
                  type: 'CURRENCY',
                  pattern: '"Rp"#,##0',
                ),
              ),
            ),
            fields: 'userEnteredFormat.numberFormat',
          ),
        ),

        // Conditional formatting: Pemasukan hijau
        Request(
          addConditionalFormatRule: AddConditionalFormatRuleRequest(
            index: 0,
            rule: ConditionalFormatRule(
              ranges: [
                GridRange(
                  sheetId: sheetId,
                  startRowIndex: 6,
                  startColumnIndex: 0,
                  endColumnIndex: 11,
                ),
              ],
              booleanRule: BooleanRule(
                condition: BooleanCondition(
                  type: 'CUSTOM_FORMULA',
                  values: [
                    ConditionValue(userEnteredValue: '=\$A7="Pemasukan"')
                  ],
                ),
                format: CellFormat(
                  backgroundColor: Color(
                    red: 0.85,
                    green: 1.0,
                    blue: 0.85,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Conditional formatting: Pengeluaran merah
        Request(
          addConditionalFormatRule: AddConditionalFormatRuleRequest(
            index: 1,
            rule: ConditionalFormatRule(
              ranges: [
                GridRange(
                  sheetId: sheetId,
                  startRowIndex: 6,
                  startColumnIndex: 0,
                  endColumnIndex: 11,
                ),
              ],
              booleanRule: BooleanRule(
                condition: BooleanCondition(
                  type: 'CUSTOM_FORMULA',
                  values: [
                    ConditionValue(userEnteredValue: '=\$A7="Pengeluaran"')
                  ],
                ),
                format: CellFormat(
                  backgroundColor: Color(
                    red: 1.0,
                    green: 0.88,
                    blue: 0.88,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    await sheetsApi.spreadsheets.batchUpdate(request, spreadsheetId);
  }

  String extractSpreadsheetId(String input) {
    final trimmed = input.trim();

    final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(trimmed);

    if (match != null) {
      return match.group(1)!;
    }

    return trimmed;
  }

  String formatDateForSheet(String inputDate) {
    final parts = inputDate.split('/');

    if (parts.length != 3) return "'$inputDate";

    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    final shortYear = year.length == 4 ? year.substring(2) : year;

    return "'$day-$month-$shortYear";
  }

  Future<String?> importSpreadsheet(String input) async {
    final spreadsheetId = extractSpreadsheetId(input);
    await saveActiveSpreadsheetId(spreadsheetId);
    return spreadsheetId;
  }

  Future<String?> createSpreadsheetFromTemplate() async {
    final driveApi = await getDriveApi();
    if (driveApi == null) return null;

    final copiedFile = drive.File()
      ..name = 'Daibudge Data - ${DateTime.now().millisecondsSinceEpoch}';

    final result = await driveApi.files.copy(
      copiedFile,
      templateSpreadsheetId,
    );

    final newSpreadsheetId = result.id;

    if (newSpreadsheetId != null) {
      await saveActiveSpreadsheetId(newSpreadsheetId);
      print('Saved Spreadsheet ID: $newSpreadsheetId');
      await applySpreadsheetStyle(newSpreadsheetId);
    }

    return newSpreadsheetId;
  }


  Future<void> appendTransactionToSheet(TransactionModel transaction) async {
    final sheetsApi = await getSheetsApi();
    if (sheetsApi == null) return;

    final spreadsheetId = await getActiveSpreadsheetId();

    print('Spreadsheet aktif: $spreadsheetId');
    print('APPEND RANGE: $sheetName!A7');

    if (spreadsheetId == null) {
      throw Exception('Tidak ada spreadsheet aktif');
    }

    await applySpreadsheetStyle(spreadsheetId);

    final row = ValueRange.fromJson({
      'values': [
        [
          transaction.type, // A: Kategori Transaksi
          formatDateForSheet(transaction.date), // B: Tanggal
          transaction.amount, // C: Nominal
          0, // D: Biaya Admin
          transaction.paymentMethod, // E: Tipe Uang
          transaction.type == 'Pemasukan'
              ? (transaction.incomeCategory ?? '')
              : '', // F: Sumber Pemasukan
          transaction.type == 'Pengeluaran'
              ? transaction.note
              : '', // G: Kategori Pengeluaran
          transaction.type == 'Transfer Internal'
              ? transaction.paymentMethod
              : '', // H: Kantong Tujuan
          transaction.note, // I: Catatan
          '', // J: kosong / cadangan
          transaction.additionalNote, // K: Catatan Tambahan
        ]
      ]
    });

    final existingRows = await sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      '$sheetName!A7:A',
    );

    final nextRow = 7 + (existingRows.values?.length ?? 0);

    await sheetsApi.spreadsheets.values.update(
      row,
      spreadsheetId,
      '$sheetName!A$nextRow:K$nextRow',
      valueInputOption: 'USER_ENTERED',
    );
  }

  Future<SheetsApi?> getSheetsApi() async {
    currentUser ??= await _googleSignIn.signInSilently();

    if (currentUser == null) {
      currentUser = await _googleSignIn.signIn();
    }

    if (currentUser == null) return null;

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) return null;

    return SheetsApi(client);
  }

  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
    currentUser = null;
  }

  String getSpreadsheetUrl(String spreadsheetId) {
    return 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit';
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive',
    ],
  );

  GoogleSignInAccount? currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    currentUser = await _googleSignIn.signIn();
    return currentUser;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    currentUser = null;
  }

  Future<void> tryAutoLogin() async {
    currentUser = await _googleSignIn.signInSilently();
  }
}