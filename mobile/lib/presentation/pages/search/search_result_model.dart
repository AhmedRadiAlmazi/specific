// Presentation Search Result Model — مشروع «مُعين» (Mouin)
// Pure presentation model. NOT a Domain entity. Built from existing
// Item aggregates returned by the Arabic search repository call.
import 'package:flutter/material.dart';
import 'package:mouin/domain/entities/item.dart';
import 'package:mouin/domain/value_objects/types.dart';
import 'search_categories.dart';

class SearchResultModel {
  final String id;
  final String title;
  final String? subtitle;
  final SearchCategory category;
  final IconData icon;
  final String? status;
  final String? metadata;
  final String entityType; // 'task', 'note', 'document', 'shopping', 'appointment', 'debt', 'reminder'
  final ItemType? itemType; // null for non-item entities
  final int entityVersion;

  const SearchResultModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.category,
    required this.icon,
    this.status,
    this.metadata,
    required this.entityType,
    this.itemType,
    this.entityVersion = 1,
  });

  /// Build from an Item aggregate (the primary path used today).
  /// Returns null if the item subtype is not in the supported result set.
  static SearchResultModel? fromItem(Item item) {
    switch (item.itemType) {
      case ItemType.task:
        return SearchResultModel(
          id: item.id,
          title: item.title,
          subtitle: item.summary,
          category: SearchCategory.tasks,
          icon: Icons.check_circle_outline,
          status: item.taskDetail?.status.name,
          metadata: item.taskDetail?.priority.name,
          entityType: 'task',
          itemType: item.itemType,
          entityVersion: item.entityVersion,
        );
      case ItemType.note:
        return SearchResultModel(
          id: item.id,
          title: item.title,
          subtitle: item.noteDetail?.content,
          category: SearchCategory.notes,
          icon: Icons.note_outlined,
          entityType: 'note',
          itemType: item.itemType,
          entityVersion: item.entityVersion,
        );
      case ItemType.document:
        return SearchResultModel(
          id: item.id,
          title: item.title,
          subtitle: item.documentDetail?.documentType,
          category: SearchCategory.documents,
          icon: Icons.description_outlined,
          status: item.documentDetail?.documentNumber,
          entityType: 'document',
          itemType: item.itemType,
          entityVersion: item.entityVersion,
        );
      case ItemType.appointment:
        return SearchResultModel(
          id: item.id,
          title: item.title,
          subtitle: item.appointmentDetail?.location,
          category: SearchCategory.tasks,
          icon: Icons.event_outlined,
          metadata: item.appointmentDetail?.startTime.toIso8601String(),
          entityType: 'appointment',
          itemType: item.itemType,
          entityVersion: item.entityVersion,
        );
      case ItemType.shopping:
        return SearchResultModel(
          id: item.id,
          title: item.title,
          subtitle: item.summary,
          category: SearchCategory.shopping,
          icon: Icons.shopping_cart_outlined,
          entityType: 'shopping',
          itemType: item.itemType,
          entityVersion: item.entityVersion,
        );
      case ItemType.debt:
        // Debt items are not searched through ItemRepository — surfaced via DebtBloc instead
        return null;
    }
  }
}
