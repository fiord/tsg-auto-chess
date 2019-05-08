const exec = require('child_process').exec;
const H = 15;
const W = 15;
const UNIT_TYPES = ["KING", "ASSASSIN", "WARRIOR", "MAGE"];
const RAND_MAX = (1 << 32) - 1;
var ID_CNT = 0;


class Unit {
    constructor (_type, _team, _level) {
        if (_level === undefined) {
            _level = 1;
        }

        this.team = _team;
        this.ID = ID_CNT;
        ID_CNT++;
        if (_type === undefined) {
            this.type = UNIT_TYPES[Math.floor(Math.random() * 3) + 1];
        }
        else {
            this.type = _type;
        }

        this.x = -1;
        this.y = -1;

        let value = 0;
        switch (this.type) {
            case "KING":
                this.HP = 100;
                this.ATK = 20;
                this.x = (W - 1) / 2;
                this.y = (_team == 1 ? 0 : H - 1);
                break;

            case "ASSASIN":
                let rand_result = (Math.floor(Math.random() * 10000) / 9999.0 * 2 - 1.0);
                value += rand_result;
                this.HP = 17 + 3 * _level + 5 * rand_result;
                rand_result = (Math.floor(Math.random() * 10000) / 9999.0 * 2 - 1.0);
                value += rand_result;
                this.ATK = 17 + 3 * _level + 5 * rand_result;
                this.value = 1 + Math.floor((value + 2.0) / 0.8);
                break;
            
            case "WARRIOR":
                let rand_result = (Math.floor(Math.random() * 10000) / 9999.0 * 2 - 1.0);
                value += rand_result;
                this.HP = 43 + 7 * _level + 10 * rand_result;
                rand_result = (Math.floor(Math.random() * 10000) / 9999.0 * 2 - 1.0);
                value += rand_result;
                this.ATK = 9 + _level + 3 * rand_result;
                this.value = 1 + Math.floor((value + 2.0) / 0.8);
                break;

            case "MAGE":
                let rand_result = (Math.floor(Math.random() * 10000) / 9999.0 * 2 - 1.0);
                value += rand_result;
                this.HP = 12 + 3 * _level + 5 * rand_result;
                rand_result = (Math.floor(Math.random() * 10000) / 9999.0 * 2 - 1.0);
                value += rand_result;
                this.ATK = 3 + 2 * _level + 3 * rand_result;
                this.value = 1 + Math.floor((value + 2.0) / 0.8)
                break;
        }
    }

    shopStr = () => {
        return `${this.ID} ${this.type} ${this.HP} ${this.ATK}\n`;
    }

    print = (_team) => {
        let outy = this.y;
        let outx = this.x;
        if (_team == 2) {
            outx = W - outxX;
            outy = H - outy;
        }

        return `${this.ID} ${this.type} ${this.HP} ${this.ATK} ${outx} ${outy}`;
    }
}