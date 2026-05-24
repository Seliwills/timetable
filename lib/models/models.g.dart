// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written to avoid build_runner dependency in scaffold

part of 'models.dart';

// ─── Timetable Adapter ────────────────────────────────────────────────────────
class TimetableAdapter extends TypeAdapter<Timetable> {
  @override final int typeId = 0;
  @override
  Timetable read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
    return Timetable(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      isActive: fields[3] as bool,
      isBuiltIn: fields[4] as bool,
    )..id = fields[0] as String;
  }
  @override
  void write(BinaryWriter writer, Timetable obj) {
    writer..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.colorValue)
      ..writeByte(3)..write(obj.isActive)
      ..writeByte(4)..write(obj.isBuiltIn);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => other is TimetableAdapter && other.typeId == typeId;
}

// ─── TimetableEntry Adapter ───────────────────────────────────────────────────
class TimetableEntryAdapter extends TypeAdapter<TimetableEntry> {
  @override final int typeId = 1;
  @override
  TimetableEntry read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
    return TimetableEntry(
      id: f[0] as String,
      timetableId: f[1] as String,
      title: f[2] as String,
      location: f[3] as String?,
      notes: f[4] as String?,
      weekday: f[5] as int,
      startMinute: f[6] as int,
      endMinute: f[7] as int,
      colorValue: f[8] as int,
      notificationsEnabled: f[9] as bool,
      reminderMinutes: f[10] as int,
    )..id = f[0] as String;
  }
  @override
  void write(BinaryWriter writer, TimetableEntry obj) {
    writer..writeByte(11)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.timetableId)
      ..writeByte(2)..write(obj.title)
      ..writeByte(3)..write(obj.location)
      ..writeByte(4)..write(obj.notes)
      ..writeByte(5)..write(obj.weekday)
      ..writeByte(6)..write(obj.startMinute)
      ..writeByte(7)..write(obj.endMinute)
      ..writeByte(8)..write(obj.colorValue)
      ..writeByte(9)..write(obj.notificationsEnabled)
      ..writeByte(10)..write(obj.reminderMinutes);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => other is TimetableEntryAdapter && other.typeId == typeId;
}

// ─── Task Adapter ─────────────────────────────────────────────────────────────
class TaskAdapter extends TypeAdapter<Task> {
  @override final int typeId = 2;
  @override
  Task read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
    return Task(
      id: f[0] as String,
      title: f[1] as String,
      description: f[2] as String?,
      timetableId: f[3] as String?,
      scheduledDate: f[4] as DateTime?,
      startMinute: f[5] as int?,
      endMinute: f[6] as int?,
      priorityIndex: f[7] as int,
      isCompleted: f[8] as bool,
      notificationsEnabled: f[9] as bool,
      reminderMinutes: f[10] as int,
      planningColumn: f[11] as String?,
      sortOrder: f[12] as int,
      createdAt: f[13] as DateTime,
    )..id = f[0] as String;
  }
  @override
  void write(BinaryWriter writer, Task obj) {
    writer..writeByte(14)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.timetableId)
      ..writeByte(4)..write(obj.scheduledDate)
      ..writeByte(5)..write(obj.startMinute)
      ..writeByte(6)..write(obj.endMinute)
      ..writeByte(7)..write(obj.priorityIndex)
      ..writeByte(8)..write(obj.isCompleted)
      ..writeByte(9)..write(obj.notificationsEnabled)
      ..writeByte(10)..write(obj.reminderMinutes)
      ..writeByte(11)..write(obj.planningColumn)
      ..writeByte(12)..write(obj.sortOrder)
      ..writeByte(13)..write(obj.createdAt);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => other is TaskAdapter && other.typeId == typeId;
}

// ─── PlanningColumn Adapter ───────────────────────────────────────────────────
class PlanningColumnAdapter extends TypeAdapter<PlanningColumn> {
  @override final int typeId = 3;
  @override
  PlanningColumn read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
    return PlanningColumn(
      id: f[0] as String,
      title: f[1] as String,
      colorValue: f[2] as int,
      sortOrder: f[3] as int,
      isInbox: f[4] as bool,
    )..id = f[0] as String;
  }
  @override
  void write(BinaryWriter writer, PlanningColumn obj) {
    writer..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.colorValue)
      ..writeByte(3)..write(obj.sortOrder)
      ..writeByte(4)..write(obj.isInbox);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => other is PlanningColumnAdapter && other.typeId == typeId;
}

// ─── AppSettings Adapter ──────────────────────────────────────────────────────
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override final int typeId = 4;
  @override
  AppSettings read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (var i = 0; i < n; i++) reader.readByte(): reader.read()};
    return AppSettings(
      globalNotifications: f[0] as bool,
      defaultReminderMinutes: f[1] as int,
      dailyDigest: f[2] as bool,
      dailyDigestHour: f[3] as int,
      dailyDigestMinute: f[4] as int,
      startOfDay: f[5] as int,
      endOfDay: f[6] as int,
      showWeekends: f[7] as bool,
    );
  }
  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer..writeByte(8)
      ..writeByte(0)..write(obj.globalNotifications)
      ..writeByte(1)..write(obj.defaultReminderMinutes)
      ..writeByte(2)..write(obj.dailyDigest)
      ..writeByte(3)..write(obj.dailyDigestHour)
      ..writeByte(4)..write(obj.dailyDigestMinute)
      ..writeByte(5)..write(obj.startOfDay)
      ..writeByte(6)..write(obj.endOfDay)
      ..writeByte(7)..write(obj.showWeekends);
  }
  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => other is AppSettingsAdapter && other.typeId == typeId;
}
