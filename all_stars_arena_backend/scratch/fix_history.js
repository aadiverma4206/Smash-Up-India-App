import fs from 'fs';
import path from 'path';

const file = path.resolve('../lib/modules/manager/views/manager_history_detail_view.dart');
let content = fs.readFileSync(file, 'utf8');

content = content.replace('FontWeight.extrabold', 'FontWeight.w800');

// Replace the duplicate closing parenthesis
const target = `                        child: Text(
                          isTeamA ? 'TEAM A' : 'TEAM B',
                          style: TextStyle(
                            color: isTeamA ? Colors.green : Colors.blue.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      ),
                    ],`;

const replacement = `                        child: Text(
                          isTeamA ? 'TEAM A' : 'TEAM B',
                          style: TextStyle(
                            color: isTeamA ? Colors.green : Colors.blue.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],`;

content = content.replace(target, replacement);

fs.writeFileSync(file, content, 'utf8');
console.log('Fixed manager_history_detail_view.dart successfully');
