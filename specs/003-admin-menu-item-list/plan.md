# Implementation Plan: Admin Menu Item List

Extend the existing Menu repository contract with Admin list and status-update
operations. Firestore remains inside the data repository. Official Riverpod
providers expose list state and an AsyncNotifier coordinates commands. The View
renders Food Ninja light components and filters the bounded result in memory.

Debug builds without an authenticated session receive an explicitly labelled
in-memory repository populated from the supplied Ngô Chicken menu. Once an
Admin session exists, Android uses Firebase. Release builds never fall back to
preview data.
