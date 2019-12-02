var show_other = function showInstrumentText(evt) {
  var selection = evt.currentTarget;
  var n = 0;
  // i hate my life.com
  for (let i = 0; i < document.getElementsByClassName("instrument-selector").length; i += 1) {
    if (document.getElementsByClassName("instrument-selector")[i] === selection) {
      n = i;
      break;
    }
  }
  var box = document.getElementsByClassName("instr-other")[n];
  if (selection.value === "Other") {
    box.style.display = "block";
  } else {
    box.style.display = "none";
  }
};

var events = [
  {
    tab_num: 0,
    target_id: "add_time",
    event_type: 'click',
    event_function: function() {
      var original = document.getElementsByClassName("time-holder")[0];
      var cln = original.cloneNode(true);
      document.getElementById("all-times-holder").appendChild(cln);
      if (document.getElementsByClassName("time-holder").length > 1) {
        document.getElementById("rem_time").style.display = "inline-block";
      }
    }
  },  
  {
    tab_num: 0,
    target_id: "rem_time",
    event_type: 'click',
    event_function: function() {
      var times = document.getElementsByClassName("time-holder");
      if (times.length <= 1) {
        return;
      }
      var holder = document.getElementById("all-times-holder");
      holder.removeChild(holder.lastChild);
      if (times.length <= 1) {
        document.getElementById("rem_time").style.display = "none";
      }
    }
  },  
  {
    tab_num: 1,
    target_id: "add_instr",
    event_type: 'click',
    event_function: function() {
      var original = document.getElementsByClassName("instrument-entry")[0];
      var cln = original.cloneNode(true);
      document.getElementById("all-instruments-holder").appendChild(cln);
      var selectors = document.getElementsByClassName("instrument-selector");
      selectors[selectors.length - 1].addEventListener('change', show_other);
      if (document.getElementsByClassName("instrument-entry").length > 1) {
        document.getElementById("rem_instr").style.display = "inline-block";
      }
    }
  },  
  {
    tab_num: 1,
    target_id: "rem_instr",
    event_type: 'click',
    event_function: function() {
      var times = document.getElementsByClassName("instrument-entry");
      if (times.length <= 1) {
        return;
      }
      var holder = document.getElementById("all-instruments-holder");
      holder.removeChild(holder.lastChild);
      if (times.length <= 1) {
        document.getElementById("rem_instr").style.display = "none";
      }
    }
  },
  {
    tab_num: -1,
    target_id: "",
    event_type: '',
    event_function: function() {
      document.getElementsByClassName("instrument-selector")[0].addEventListener('change', show_other);
    }
  }
];

Driver.init(events);