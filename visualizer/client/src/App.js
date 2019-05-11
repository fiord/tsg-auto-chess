import React from 'react';
import {
  Container,
  Form,
  FormGroup,
  Input,
  Label,
  } from 'reactstrap';
import './App.css';

var field = new Array(15);
for(let i = 0; i < 15; i++) {
  field[i] = new Array(15).fill(null);
}
var shops = [[], []]
var warehouse = [[], []]

class App extends React.Component {
  constructor(props) {
    super(props);
    this.fetchData = this.fetchData.bind(this);
    this.onChangeSelect = this.onChangeSelect.bind(this);
    this.updateField = this.updateField.bind(this);
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
      warehouse: [[], []],
      timer: null,
    };
  }

  fetchData() {
    console.log("OK");
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
          let timer = setInterval(this.updateField, 500);
          this.setState({timer});
        });
    }
    this.setState({filename: e.target.value});
  }

  updateField() {
    console.log(this.state);
    // this.state.turnを表示
    let i = this.state.turn;
    field = JSON.parse(this.state.default_field);
    warehouse = [[], []];
    for(let j = 0; j < 2; j++) {
      for(let k = 0; k < this.state.data[i].units[j].length; k++) {
        if (this.state.data[i].units[j][k].x == -1) {
          warehouse[j].push(this.state.data[i].units[j][k]);
        }
        else {
          field[this.state.data[i].units[j][k].y][this.state.data[i].units[j][k].x] = this.state.data[i].units[j][k];
        }
      }
    }


    console.log(i+1);
    this.setState({turn: i + 1});
    console.log([this.state.data[i].units[0][0].hp, this.state.data[i].units[1][0].hp]);
    this.setState({hp: [this.state.data[i].units[0][0].hp, this.state.data[i].units[1][0].hp]});
    console.log(this.state.data[i].left_times);
    this.setState({left_time: this.state.data[i].left_times});
    console.log(this.state.data[i].levels);
    this.setState({level: this.state.data[i].levels});
    console.log(this.state.data[i].golds);
    this.setState({gold: this.state.data[i].golds});
    console.log(this.state.data[i].shops);
    shops = this.state.data[i].shops;
    console.log(field);
    console.log(warehouse);

    console.log(`turn=${i}`);
    console.log(this.state);
    if(i + 1 === 50) {
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
              <option></option>
              {this.state.filelist.map((file) => {
                return (<option>{file}</option>);
              })}
            </Input>
          </FormGroup>
        </Form>
        <p>Turn: {this.state.turn}</p>
        <div>
          <font color="red">{this.state.result[0]} {this.state.name[0]} {this.state.hp[0]} {this.state.level[0]} {this.state.gold[0]}</font>
          <ul>
            {[...Array(3).keys()].map((i) => {
              // this.state.shop[0][i]
              return (<li>{shops[0][i]}</li>);
            })}
          </ul>
        </div>
        <div>
          <table>
          {[...Array(15).keys()].map((i) => {
            return (
              <tr>
                {[...Array(15).keys()].map((j) => {
                  if(field[i][j] === null) {
                    return (<td><div></div></td>);
                  }
                  else {
                    return (<td><div>{field[i][j]}</div></td>);
                  }
                })}
              </tr>
            );
          })}
          </table>
        </div>
        <div>
          <font color="blue">{this.state.result[1]} {this.state.name[1]} {this.state.hp[1]} {this.state.level[1]} {this.state.gold[1]}</font>
          <ul>
          {[...Array(3).keys()].map((i) => {
            return (<li>{shops[1][i]}</li>);
          })}
          </ul>
        </div>
      </Container>
    );
  }
}

export default App;
