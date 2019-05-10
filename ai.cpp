#include <bits/stdc++.h>
using namespace std;

const int MAX_TURN = 1000;
const int H = 15;
const int W = 15;
enum UNIT_TYPE {
    KING,
    ASSASSIN,
    WARRIOR,
    MAGE,
    NONE
};
int dy[] = {1, 1, 1, 0, 0, -1, -1, -1};
int dx[] = {1, 0, -1, 1, -1, 1, 0, -1};

class Units {
    public:
    int id;
    UNIT_TYPE type;
    int x;
    int y;
    int hp;
    int atk;
    int value;
    Units() {
      id=x=y=hp=atk=value=-1;
      type=NONE;
    }
    Units(int _id, UNIT_TYPE _type, int _hp, int _atk, int _x, int _y, int _value):id(_id), type(_type), hp(_hp), atk(_atk), x(_x), y(_y), value(_value) {
    }
};

Units getShop() {
    int id, hp, atk, value;
    string s;
    cin>>id>>s>>hp>>atk>>value;
    Units ret = Units();
    ret.id=id;
    ret.hp = hp;
    ret.atk = atk;
    ret.x = ret.y = -1;
    ret.value = value;
    if(s=="ASSASSIN") {
        ret.type = ASSASSIN;
    }
    else if(s=="WARRIOR") {
        ret.type = WARRIOR;
    }
    else if(s=="MAGE") {
        ret.type = MAGE;
    }
    return ret;
}

Units getUnit() {
    int id, hp, atk, x, y;
    string type;    cin>>id>>type>>hp>>atk>>x>>y;
    Units ret = Units();
    ret.id = id;
    ret.hp = hp;
    ret.atk = atk;
    ret.x = x;
    ret.y = y;
    if(type=="KING") {
        ret.type = KING;
    }
    else if(type=="ASSASSIN") {
        ret.type = ASSASSIN;
    }
    else if(type == "WARRIOR") {
        ret.type = WARRIOR;
    }
    else if(type == "MAGE") {
        ret.type = MAGE;
    }
    return ret;
}

int main() {
    srand((unsigned)time(NULL));
    cout<<"Sample_AI"<<endl;
    int turn = 0;
    while(++turn < MAX_TURN) {
        cin >> turn;
        int time_left;  cin>>time_left;
        int myLevel,oppLevel;   cin>>myLevel>>oppLevel;
        int myGold, oppGold;    cin>>myGold>>oppGold;
        vector<Units> shop(3);
        for(int i = 0; i < 3; i++) {
            shop[i] = getShop();
        }
        int n;  cin>>n;
        vector<Units> Align(n);
        for(int i = 0; i < n; i++) {
            Align[i] = getUnit();
        }
        int m;  cin>>m;
        vector<Units> Enemy(m);
        for(int i = 0; i < m; i++) {
            Enemy[i] = getUnit();
        }

        int command_num = rand()%5;
        if(command_num == 0) {
            cout<<"reset WARRIOR ASSASSIN MAGE"<<endl;
        }
        else if(command_num == 1) {
            int selected = rand()%3;
            cout<<"buy "<<shop[selected].id<<endl;
        }
        else if(command_num == 2) {
            vector<int> targets;
            for(int i = 0; i < Align.size(); i++) {
                if(Align[i].x==-1) targets.push_back(i);
            }
            if(targets.size()>0) {
                int target = rand()%targets.size();
                int tx = Align[0].x + (rand()%7)-3;
                int ty = Align[0].y + (rand()%7)-3;
                cout<<"move "<<Align[targets[target]].id<<" "<<tx<<" "<<ty<<endl;
            }
            else {
                cout<<"nop"<<endl;
            }
        }
        else if(command_num == 3) {
            vector<vector<int>> memo(4, vector<int>());
            for(int i = 0 ; i < Align.size(); i++){
                if(Align[i].x == -1)    memo[Align[i].type].push_back(i);
            }
            bool nop = true;;
            for(int i = 1; i <= 3; i++) {
                if(memo[i].size() >= 3) {
                    cout<<"evolve "<<Align[memo[i][0]].id<<" "<<Align[memo[i][1]].id<<" "<<Align[memo[i][2]].id<<endl;
                    nop=false;
                    break;
                }
            }
            if(nop) {
                cout<<"nop"<<endl;
            }
        }
        else if(command_num == 4) {
            cout<<"levelup"<<endl;
        }

        vector<string> out;
        for(int i = 0; i < Align.size(); i++) {
            if(Align[i].x != -1) {
                int dir = rand()%8;
                out.push_back(to_string(Align[i].id) + " " + to_string(Align[i].x + dx[dir]) + " " + to_string(Align[i].y + dy[dir]));\
            }
        }
        cout<<out.size()<<endl;
        for(int i = 0 ; i < out.size(); i++) {
            cout<<out[i]<<endl;
        }
    }
}
