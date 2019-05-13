import React from 'react';
import {
  Container,
  Form,
  FormGroup,
  Input,
  Label,
  } from 'reactstrap';
import './App.css';

class App extends React.Component {
  constructor(props) {
    super(props);
    this.fetchData = this.fetchData.bind(this);
    this.onChangeSelect = this.onChangeSelect.bind(this);
    this.updateField = this.updateField.bind(this);
    let field = new Array(9);
    for(let i = 0; i < 9; i++) {
      field[i] = new Array(9).fill(null);
    }
    this.state = {
      filename: "",
      filelist: [],
      data: null,
      turn: 0,
      name: ["", ""],
      result: ["", ""],
      left_time: ["", ""],
      hp: ["", ""],
      level: ["", ""],
      gold: ["", ""],
      default_field: JSON.stringify(field),
      field: JSON.parse(JSON.stringify(field)),
      shop: [[], []],
      timer: null,
    };
  }

  fetchData() {
    return fetch('/_api/').then(res => res.json())
      .then((res) => {
        console.log(res);
        this.setState({filelist: res});
      });
  }

  onChangeSelect(e) {
    if (this.state.filename !== e.target.value && e.target.value !== "") {
      fetch(`/_api/${e.target.value}`).then(res => res.json())
        .then((res) => {
          console.log(res);
          this.setState({data: res.field, name: res.names, result: res.result, turn: 0});
          let timer = setInterval(this.updateField, 1000);
          this.setState({timer});
        });
    }
    this.setState({filename: e.target.value});
  }

  updateField() {
    // this.state.turnを表示
    let i = this.state.turn;
    let field = JSON.parse(this.state.default_field);
    for(let j = 0; j < 2; j++) {
      for(let k = 0; k < this.state.data[i].units[j].length; k++) {
        field[8 - this.state.data[i].units[j][k].y][8 - this.state.data[i].units[j][k].x] = this.state.data[i].units[j][k];
      }
    }
    let hp = [0, 0];
    for (let j = 0; j < 2; j++) {
      if (this.state.data[i].units[j].length > 0) {
        hp[j] = this.state.data[i].units[j][0].hp;
      }
    }

    this.setState({turn: i + 1});
    this.setState({hp});
    this.setState({left_time: this.state.data[i].left_times});
    this.setState({level: this.state.data[i].levels});
    this.setState({gold: this.state.data[i].golds});
    this.setState({shop: this.state.data[i].shops});
    this.setState({field});

    if(i + 1 === this.state.data.length) {
      let timer = this.state.timer;
      clearInterval(timer);
      this.setState({timer});
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  render() {
    return (
      <Container>
        <Form>
          <FormGroup>
            <Label for="filenames">filename:</Label>
            <Input type="select" name="select" id="filenames" onChange={this.onChangeSelect} value={this.state.filename}>
              <option key={"no file"}></option>
              {this.state.filelist.map((file) => {
                return (<option key={file}>{file}</option>);
              })}
            </Input>
          </FormGroup>
        </Form>
        <p>Turn: {this.state.turn}</p>
        <div>
          <font color="red">Died:{this.state.result[0]} Name:{this.state.name[0]} 残り時間:{Math.floor(this.state.left_time[0])} King'sHP:{this.state.hp[0]} Level:{this.state.level[0]} Gold:{this.state.gold[0]}</font>
          <ul key={"shop-player_a"}>
            <li key="shop_player_a-nop">
              <div style={{height: "40px"}}>
              </div>
            </li>
            {this.state.shop[0].map((obj, i) => (<li key={"shop-player_a-"+i} style={{border: "solid"}}>
              <center>
              <div className="circle" style={{borderRadius: "50%", height: "50px", width: "50px", backgroundColor: (obj.type==="WARRIOR"?"cyan":(obj.type==="MAGE"?"yellow":"magenta")), border: "solid red"}}>
                {obj.hp}/{obj.atk}
              </div>
              <p style={{margin: 0}}>{obj.type}</p>
              <p style={{margin: 0}}>$ {obj.val}</p>
              </center>
            </li>))}
          </ul>
        </div>
        <div>
          <table>
          <tbody>
          {[...Array(9).keys()].map((i) => {
            return (
              <tr key={"fieldrow_"+i}>
                {[...Array(9).keys()].map((j) => {
                  if(this.state.field[i][j] === null) {
                    return (<td key={"field_"+i+"-"+j}><div style={{height: "50px", width: "50px"}}></div></td>);
                  }
                  else {
                    return (<td key={"field_"+i+"-"+j}>
                      <div className="circle" style={{borderRadius: (this.state.field[i][j].team==0 ? "50%" : "0%"), height: "50px", width: "50px", backgroundColor: (this.state.field[i][j].type==="WARRIOR"?"cyan":(this.state.field[i][j].type==="MAGE"?"yellow":(this.state.field[i][j].type==="ASSASSIN"?"magenta":"gold"))), border: (this.state.field[i][j].team==0 ? "solid red" : "solid blue")}}>
                        {this.state.field[i][j].hp}/{this.state.field[i][j].atk}
                      </div></td>);
                  }
                })}
              </tr>
            );
          })}
          </tbody>
          </table>
        </div>
        <div>
          <font color="blue">Died:{this.state.result[1]} Name:{this.state.name[1]} 残り時間:{Math.floor(this.state.left_time[1])} King'sHP:{this.state.hp[1]} Level:{this.state.level[1]} Gold:{this.state.gold[1]}</font>
          <ul key="ul-player_b">
            <li key="shopplayer_b-nop">
              <div style={{height: "40px"}}>
              </div>
            </li>
          {this.state.shop[1].map((obj, i) => {
            return (<li key={"shopplayer_b"+i} style={{border: "solid"}}>
              <center>
              <div className="circle" style={{height: "50px", width: "50px", backgroundColor: (obj.type==="WARRIOR"?"cyan":(obj.type==="MAGE"?"yellow":"magenta")), border: "solid blue"}}>
                {obj.hp}/{obj.atk}
              </div>
              <p style={{margin: 0}}>{obj.type}</p>
              <p style={{margin: 0}}>$ {obj.val}</p>
              </center>
            </li>);
          })}
          </ul>
        </div>
      </Container>
    );
  }
}

export default App;
