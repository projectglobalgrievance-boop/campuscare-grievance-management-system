/// The seven departments a complaint can be routed to. Mirrors
/// DEPARTMENT_ROUTING / DEPARTMENT_NAMES in ai-service/app/categories.py and
/// the isDepartment() list in firestore.rules — keep all three in step.
class Department {
  final String id;
  final String name;
  final String category; // the complaint category this department handles
  final String handles; // plain-words hint for the student picking it

  const Department(this.id, this.name, this.category, this.handles);

  static const all = [
    Department('housekeeping', 'Facilities', 'Cleanliness',
        'Dustbins, dirty floors, washrooms, pests'),
    Department('electrical_maintenance', 'Maintenance',
        'Electrical', 'Fans, lights, sockets, power cuts'),
    Department('plumbing_maintenance', 'Utilities', 'Plumbing',
        'Taps, leaks, blocked drains, water supply'),
    Department('carpentry', 'Infrastructure', 'Furniture',
        'Benches, desks, chairs, doors, windows'),
    Department('academic_office', 'Academic Office', 'Academics',
        'Classes, timetable, labs, exams, faculty'),
    Department('hostel_office', 'Hostel Office', 'Hostel',
        'Rooms, mess food, hostel facilities'),
    Department('general_administration', 'General Administration', 'Other',
        'Anything else'),
  ];

  static Department? byId(String? id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  static String nameOf(String? id) => byId(id)?.name ?? 'Unassigned';
}
