import 'package:flutter_test/flutter_test.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'package:mouin/application/commands/item_commands.dart';
import 'package:mouin/application/use_cases/item_use_cases.dart';
import 'package:mouin/infrastructure/database/local_sqlite_db.dart';
import 'package:mouin/infrastructure/repositories/local_item_repository.dart';

void main() {
  group('Phase 4.1 Unified Item Domain & Factory Tests', () {
    test('createNote factory initializes correctly with NoteDetail', () {
      final note = Item.createNote(
        id: 'note-01',
        workspaceId: 'ws-01',
        title: 'ملاحظة اجتماع الفكرة',
        content: 'محتوى الملاحظة بصيغة ماركداون',
      );

      expect(note.id, 'note-01');
      expect(note.itemType, ItemType.note);
      expect(note.isNote, isTrue);
      expect(note.noteDetail, isNotNull);
      expect(note.noteDetail!.content, 'محتوى الملاحظة بصيغة ماركداون');
      expect(note.noteDetail!.contentFormat, 'plain_text');
      expect(note.isDeleted, isFalse);
    });

    test('createAppointment factory initializes correctly with AppointmentDetail', () {
      final start = DateTime.now().toUtc();
      final appt = Item.createAppointment(
        id: 'appt-01',
        workspaceId: 'ws-01',
        title: 'موعد الطبيب',
        startTime: start,
        location: 'صنعاء - المستشفى',
      );

      expect(appt.id, 'appt-01');
      expect(appt.itemType, ItemType.appointment);
      expect(appt.isAppointment, isTrue);
      expect(appt.appointmentDetail, isNotNull);
      expect(appt.appointmentDetail!.location, 'صنعاء - المستشفى');
      expect(appt.appointmentDetail!.startTime, start);
    });

    test('createDocument factory initializes correctly with DocumentDetail', () {
      final doc = Item.createDocument(
        id: 'doc-01',
        workspaceId: 'ws-01',
        title: 'جواز السفر',
        documentType: 'passport',
        documentNumber: 'P12345678',
        issuingAuthority: 'مصلحة الهجرة والجوازات',
      );

      expect(doc.id, 'doc-01');
      expect(doc.itemType, ItemType.document);
      expect(doc.isDocument, isTrue);
      expect(doc.documentDetail, isNotNull);
      expect(doc.documentDetail!.documentNumber, 'P12345678');
      expect(doc.documentDetail!.issuingAuthority, 'مصلحة الهجرة والجوازات');
    });

    test('soft delete marks deletedAt and increments version', () {
      final task = Item.createTask(
        id: 'task-del-01',
        workspaceId: 'ws-01',
        title: 'مهمة للحذف',
      );

      final deleted = task.markDeleted();
      expect(deleted.isDeleted, isTrue);
      expect(deleted.deletedAt, isNotNull);
      expect(deleted.entityVersion, 2);
    });
  });

  group('Phase 4.1 ItemUseCases & Local Persistence Tests', () {
    late LocalSqliteDb db;
    late LocalItemRepository itemRepo;
    late LocalOutboxRepository outboxRepo;
    late ItemUseCases useCases;

    setUp(() {
      db = LocalSqliteDb();
      itemRepo = LocalItemRepository(db);
      outboxRepo = LocalOutboxRepository(db);
      useCases = ItemUseCases(itemRepository: itemRepo, outboxRepository: outboxRepo);
    });

    test('createNote use case saves note locally and enqueues Outbox insert', () async {
      final cmd = CreateNoteCommand(
        workspaceId: 'ws-01',
        title: 'فكرة مشروع جديدة',
        content: 'تفاصيل الفكرة',
      );

      final res = await useCases.createNote(cmd);
      expect(res.isSuccess, isTrue);
      final note = res.value;

      expect(note.itemType, ItemType.note);
      expect(note.title, 'فكرة مشروع جديدة');

      // Verify saved in DB
      final getRes = await itemRepo.getById('ws-01', note.id);
      expect(getRes.isSuccess, isTrue);
      expect(getRes.value?.noteDetail?.content, 'تفاصيل الفكرة');

      // Verify outbox
      final outboxRes = await outboxRepo.getPendingOperations();
      expect(outboxRes.isSuccess, isTrue);
      expect(outboxRes.value.length, 1);
      expect(outboxRes.value.first['entity_type'], 'item');
      expect(outboxRes.value.first['payload']['item_type'], 'note');
    });

    test('createAppointment use case saves appointment and enqueues Outbox', () async {
      final cmd = CreateAppointmentCommand(
        workspaceId: 'ws-01',
        title: 'اجتماع الشركة',
        startTime: DateTime.now().toUtc(),
        location: 'قاعة الاجتماعات',
      );

      final res = await useCases.createAppointment(cmd);
      expect(res.isSuccess, isTrue);
      final appt = res.value;

      final getRes = await itemRepo.getById('ws-01', appt.id);
      expect(getRes.isSuccess, isTrue);
      expect(getRes.value?.appointmentDetail?.location, 'قاعة الاجتماعات');
    });

    test('updateItem and softDelete work across unified items', () async {
      final cmd = CreateNoteCommand(
        workspaceId: 'ws-01',
        title: 'ملاحظة قابلة للتعديل',
        content: 'المحتوى 1',
      );
      final createRes = await useCases.createNote(cmd);
      final noteId = createRes.value.id;

      // Update
      final updateRes = await useCases.updateItem(UpdateItemCommand(
        workspaceId: 'ws-01',
        itemId: noteId,
        title: 'ملاحظة معدلة بنجاح',
      ));
      expect(updateRes.isSuccess, isTrue);
      expect(updateRes.value.title, 'ملاحظة معدلة بنجاح');

      // Soft delete
      final delRes = await useCases.softDelete(SoftDeleteItemCommand(
        workspaceId: 'ws-01',
        itemId: noteId,
      ));
      expect(delRes.isSuccess, isTrue);

      final listRes = await useCases.listItems('ws-01');
      expect(listRes.isSuccess, isTrue);
      expect(listRes.value.isEmpty, isTrue);
    });
  });
}
