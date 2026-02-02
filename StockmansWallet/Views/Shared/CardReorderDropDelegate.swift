//
//  CardReorderDropDelegate.swift
//  StockmansWallet
//
//  Shared drag-and-drop delegate for reordering card lists.
//  Debug: Centralized behavior to keep dashboard and portfolio consistent.
//

import SwiftUI

// Debug: Generic drop delegate for card reordering using string IDs.
struct CardReorderDropDelegate: DropDelegate {
    let itemId: String
    @Binding var draggedCardId: String?
    @Binding var isReorderMode: Bool
    let onMove: (String, String) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedCardId,
              draggedCardId != itemId else { return }
        onMove(draggedCardId, itemId)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // Debug: Reset reorder mode and dragging state after drop completes.
        draggedCardId = nil
        isReorderMode = false
        return true
    }
}

