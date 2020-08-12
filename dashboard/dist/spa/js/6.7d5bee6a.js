(window["webpackJsonp"]=window["webpackJsonp"]||[]).push([[6],{2777:function(e,t,n){"use strict";n.r(t);var r=function(){var e=this,t=e.$createElement,n=e._self._c||t;return n("div",[e.showTitle?n("h4",{staticClass:"q-mt-md"},[e._v("\n    Activity Overview for "+e._s(e.courses.join(", "))+"\n  ")]):e._e(),e._e(),n("LastUserInteraction"),n("IndividualMetrics")],1)},a=[],i=(n("8e6e"),n("8a81"),n("ac6a"),n("cadf"),n("06db"),n("456d"),n("c47a")),o=n.n(i),s=function(){var e=this,t=e.$createElement,n=e._self._c||t;return n("DashboardComponent",{attrs:{title:"Aggregate Metrics"}},[n("q-zoom",{ref:"activityOverviewZoom",attrs:{manual:""}},[n("q-btn",{attrs:{color:"secondary",label:"Zoom In"},on:{click:e.toggleZoom}}),n("q-table",{attrs:{title:"Individual student metrics",dense:"",data:e.data,columns:e.columns,"row-key":function(e){return e.id},pagination:e.pagination,selection:"multiple",selected:e.selected,"selected-rows-label":e.getSelectedString},on:{"update:pagination":function(t){e.pagination=t},"update:selected":function(t){e.selected=t}}})],1),n("q-btn",{staticClass:"q-my-md q-mr-md",attrs:{color:"primary",label:"Export as CSV"},on:{click:function(t){return e.exportColumnsToCSV()}}}),n("q-btn",{staticClass:"q-my-md q-mr-md",attrs:{color:"primary",label:"Export email"},on:{click:function(t){return e.exportColumnsToCSV([{name:"email",field:function(e){return e.email}}]," ; ")}}}),n("q-editor",{directives:[{name:"show",rawName:"v-show",value:e.showEditor,expression:"showEditor"}],attrs:{toolbar:[]},model:{value:e.editor,callback:function(t){e.editor=t},expression:"editor"}})],1)},c=[],u=n("d624"),l=n.n(u),m=n("4db1"),d=n.n(m),g=(n("c5f6"),n("9530")),p=n.n(g),f=function(){var e=this,t=e.$createElement,n=e._self._c||t;return n("div",[n("q-card",{staticClass:"my-card bg-grey-1 q-my-lg"},[n("q-card-section",[n("div",{staticClass:"row items-center no-wrap"},[n("div",{staticClass:"col"},[n("div",{staticClass:"text-h6"},[e._v(e._s(e.title))]),n("div",{directives:[{name:"show",rawName:"v-show",value:e.subtitle,expression:"subtitle"}],staticClass:"text-subtitle2"},[e._v(e._s(e.subtitle))])]),n("div",{staticClass:"col-auto"},[n("q-btn",{attrs:{color:"grey-7",round:"",flat:"",icon:"more_vert"}},[n("q-menu",{attrs:{cover:"","auto-close":""}},[n("q-list",[n("q-item",{attrs:{clickable:""}},[n("q-item-section",[e._v("Remove Card")])],1),n("q-item",{attrs:{clickable:""}},[n("q-item-section",[e._v("Send Feedback")])],1),n("q-item",{attrs:{clickable:""}},[n("q-item-section",[e._v("Share")])],1)],1)],1)],1)],1)])]),n("q-card-section",[e._t("default",[e._v("Default content")])],2),n("q-separator"),n("q-card-actions",{directives:[{name:"show",rawName:"v-show",value:!1,expression:"false"}]},[n("q-btn",{attrs:{flat:""}},[e._v("Action 1")]),n("q-btn",{attrs:{flat:""}},[e._v("Action 2")])],1)],1)],1)},b=[],v={props:{title:String,subtitle:String},data:function(){return{}}},h=v,_=n("2877"),O=n("eebe"),y=n.n(O),w=n("f09f"),S=n("a370"),q=n("9c40"),j=n("4e73"),$=n("1c1c"),C=n("66e5"),P=n("4074"),I=n("eb85"),F=n("4b7e"),D=Object(_["a"])(h,f,b,!1,null,null,null),T=D.exports;y()(D,"components",{QCard:w["a"],QCardSection:S["a"],QBtn:q["a"],QMenu:j["a"],QList:$["a"],QItem:C["a"],QItemSection:P["a"],QSeparator:I["a"],QCardActions:F["a"]});var E=n("2f62"),x=n("bd4c");function k(){var e=l()(['\n        query useAggregateMetrics(\n          $courses: [String!]\n          $students: [String!]\n          $timeFrom: timestamp!\n          $timeTo: timestamp!\n        ) {\n          users: auth_user(\n            where: {\n              _and: {\n                username: { _in: $students }\n                active: { _eq: "T" }\n                course_name: { _in: $courses }\n              }\n            }\n          ) {\n            id\n            firstName: first_name\n            lastName: last_name\n            username\n            email\n            courseName: course_name\n            allInteractionsCount: useinfos_aggregate(\n              distinct_on: [timestamp]\n              order_by: { timestamp: asc }\n\n              where: { timestamp: { _gte: $timeFrom, _lte: $timeTo } }\n            ) {\n              aggregate {\n                count\n              }\n            }\n            lastInteractionTimestamp: useinfos(\n              limit: 1\n              order_by: { timestamp: desc }\n            ) {\n              timestamp\n              id\n            }\n            pageViews: useinfos_aggregate(\n              where: {\n                event: { _eq: "page" }\n                timestamp: { _gte: $timeFrom, _lte: $timeTo }\n              }\n            ) {\n              aggregate {\n                count\n              }\n            }\n            activecodeRuns: useinfos_aggregate(\n              distinct_on: [timestamp, event, act]\n              order_by: { timestamp: asc, event: asc, act: asc }\n              where: {\n                event: { _eq: "activecode" }\n                act: { _eq: "run" }\n                timestamp: { _gte: $timeFrom, _lte: $timeTo }\n              }\n            ) {\n              aggregate {\n                count\n              }\n            }\n            activecodeErrors: useinfos_aggregate(\n              where: {\n                event: { _eq: "ac_error" }\n                timestamp: { _gte: $timeFrom, _lte: $timeTo }\n              }\n            ) {\n              aggregate {\n                count\n              }\n            }\n            mChoice: useinfos_aggregate(\n              where: {\n                event: { _eq: "mChoice" }\n                timestamp: { _gte: $timeFrom, _lte: $timeTo }\n              }\n            ) {\n              aggregate {\n                count\n              }\n            }\n            shortAnswers: useinfos_aggregate(\n              where: {\n                event: { _eq: "shortanswer" }\n                timestamp: { _gte: $timeFrom, _lte: $timeTo }\n              }\n            ) {\n              aggregate {\n                count\n              }\n            }\n            videosTouched: useinfos_aggregate(\n              where: {\n                event: { _eq: "video" }\n                timestamp: { _gte: $timeFrom, _lte: $timeTo }\n              }\n            ) {\n              aggregate {\n                count\n              }\n            }\n            videosCompleted: useinfos_aggregate(\n              where: {\n                event: { _eq: "video" }\n                act: { _eq: "complete" }\n                timestamp: { _gte: $timeFrom, _lte: $timeTo }\n              }\n            ) {\n              aggregate {\n                count\n              }\n            }\n          }\n        }\n      ']);return k=function(){return e},e}function N(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function Q(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?N(n,!0).forEach((function(t){o()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):N(n).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}var R={components:{DashboardComponent:T},props:{itemsPerPage:{type:Number,default:30}},data:function(){var e=this;return{data:[],showEditor:!1,editor:"",selected:[],pagination:{rowsPerPage:30},columns:[{name:"name",align:"left",label:"Name",field:function(e){var t=e.firstName,n=e.lastName,r=e.username;return"".concat(t," ").concat(n," (").concat(r,")")},sortable:!0},{name:"allInteractionsCount",label:"# All Interactions",field:function(e){return e.allInteractionsCount.aggregate.count},sortable:!0},{name:"lastInteractionTimestamp",label:"Last Interaction date",field:function(e){var t=e.lastInteractionTimestamp,n=t[0]&&t[0].timestamp;return n},format:function(t){return x["a"].formatDate(t,e.dateFormat)},sortable:!0,sort:function(e,t){return new Date(e)-new Date(t)}},{name:"activecodeRuns",label:"# Code runs",field:function(e){return e.activecodeRuns.aggregate.count},sortable:!0},{name:"activecodeErrors",label:"# Code Errors",field:function(e){return e.activecodeErrors.aggregate.count},sortable:!0},{name:"mChoice",label:"# Multiple Choice Attempts",field:function(e){return e.mChoice.aggregate.count},sortable:!0},{name:"pageViews",label:"# Page views",field:function(e){return e.pageViews.aggregate.count},sortable:!0},{name:"videosTouched",label:"# Videos Started",field:function(e){return e.videosTouched.aggregate.count},sortable:!0},{name:"videosCompleted",label:"# Videos Completed",field:function(e){return e.videosCompleted.aggregate.count},sortable:!0}]}},methods:{toggleZoom:function(){this.$refs.activityOverviewZoom.toggle()},exportColumnsToCSV:function(e){var t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:"<br>";e=e||[].concat(d()(this.columns),[{name:"firstName",field:function(e){return e.firstName}},{name:"lastName",field:function(e){return e.lastName}},{name:"email",field:function(e){return e.email}},{name:"username",field:function(e){return e.username}}]);var n=function(t){return e.map((function(e){return e.field(t)}))};this.editor="",this.editor=this.selected.map((function(e){return n(e)})).map((function(e){return e.join(";")})).join(t),this.showEditor=!0},getSelectedString:function(){return 0===this.selected.length?"":"".concat(this.selected.length," record").concat(this.selected.length>1?"s":""," selected of ").concat(this.data.length)}},computed:Q({},Object(E["c"])("dataFilters",["timeRange","courses"]),{},Object(E["c"])(["dataFilters"]),{},Object(E["c"])("config",["dateFormat"]),{},Object(E["b"])("dataFilters",["timeRangeString","selectedStudents"])),apollo:{userActivityStats:{query:p()(k()),variables:function(){var e=this.dataFilters.courses,t=this.selectedStudents.map((function(e){return e.username}));return{courses:e,students:t,timeFrom:this.timeRange.from.toISOString(),timeTo:this.timeRange.to.toISOString()}},debounce:1e3,pollInterval:3e4,result:function(e){var t=e.data;this.data=t.users}}}},L=R,A=n("eaac"),V=n("d66b"),M=Object(_["a"])(L,s,c,!1,null,null,null),G=M.exports;y()(M,"components",{QBtn:q["a"],QTable:A["a"],QEditor:V["a"]});var Z=function(){var e=this,t=e.$createElement,n=e._self._c||t;return n("div",[n("DashboardComponent",{attrs:{title:e.sinceDateLoggedInText}},[n("div",[n("p",[e._v(e._s(e.connectedStudents.length)+" students logged")]),n("q-list",{attrs:{separator:"",dense:""}},e._l(e.connectedStudents,(function(t){return n("q-item",{key:t.username},[n("q-item-section",[e._v("\n            "+e._s(t.auth_user.first_name)+"\n            "+e._s(t.auth_user.last_name)+"\n          ")])],1)})),1)],1)])],1)},B=[];function U(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function J(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?U(n,!0).forEach((function(t){o()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):U(n).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function z(){var e=l()(['\n  query connectedStudents(\n    $courses: [String!]\n    $timeFrom: timestamp!\n    $timeTo: timestamp!\n    $limit: Int!\n  ) {\n    connectedStudents: auth_event(\n      distinct_on: [user_id]\n      order_by: { user_id: asc, auth_user: { course_name: asc } }\n      limit: $limit\n      where: {\n        _and: {\n          time_stamp: { _gte: $timeFrom, _lte: $timeTo }\n          description: { _like: "User%Logged-in" }\n          auth_user: {\n            _and: { username: { _neq: "donc" }, course_name: { _in: $courses } }\n          }\n        }\n      }\n    ) {\n      time_stamp\n      id\n      auth_user {\n        username\n        first_name\n        last_name\n        course_name\n      }\n    }\n  }\n']);return z=function(){return e},e}var H=p()(z()),K={name:"LiveStudentsConnected",components:{DashboardComponent:T},props:{since:{type:Object,required:!0}},data:function(){return{content:"salut les amis",connectedStudents:[],sinceDate:this.since}},computed:J({},Object(E["c"])("dataFilters",["timeRange","courses"]),{},Object(E["c"])("config",["dateFormat"]),{},Object(E["b"])("dataFilters",["timeRangeString"]),{sinceDateLoggedInText:function(){return"Logged-in between \n          ".concat(this.timeRangeString.from,"\n          and\n          ").concat(this.timeRangeString.to)},courseName:function(){return this.$route.params.courseName}}),methods:{formatDate:function(e){return x["a"].formatDate(e,this.CONFIG_DATE_FORMAT)}},apollo:{connectedStudents:{query:H,variables:function(){return{courses:this.courses,timeFrom:this.timeRange.from.toISOString(),timeTo:this.timeRange.to.toISOString(),limit:30}},pollInterval:1e4,debounce:1e3,result:function(e){var t=e.data,n=e.loading;this.loading=n,this.connectedStudents=t.connectedStudents}}}},W=K,X=Object(_["a"])(W,Z,B,!1,null,null,null),Y=X.exports;y()(X,"components",{QList:$["a"],QItem:C["a"],QItemSection:P["a"]});var ee=function(){var e=this,t=e.$createElement,n=e._self._c||t;return n("div",[n("DashboardComponent",{directives:[{name:"show",rawName:"v-show",value:!0,expression:"true"}],attrs:{title:"Student interactions between "+e.timeRangeString.from+" and "+e.timeRangeString.to}},[n("div",[n("q-table",{attrs:{dense:"","table-header-style":{backgroundColor:"rgb(90, 90, 90, 11)",color:"rgb(255, 255, 255, 1)"},pagination:e.pagination,data:e.interactions,columns:e.columns,"no-data-label":"No student interaction for these search criteria"},on:{"update:pagination":function(t){e.pagination=t}}}),n("q-checkbox",{attrs:{label:"Live update"},model:{value:e.shouldGoLive,callback:function(t){e.shouldGoLive=t},expression:"shouldGoLive"}})],1)]),e._e()],1)},te=[];n("28a5"),n("7f7f");function ne(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function re(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?ne(n,!0).forEach((function(t){o()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):ne(n).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function ae(){var e=l()(["\n  query lastInteractions(\n    $courses: [String!]\n    $usernames: [String!]\n    $timeFrom: timestamp!\n    $timeTo: timestamp!\n    $limit: Int!\n  ) {\n    instructors: auth_user(\n      where: {\n        _and: {\n          course_instructors: {\n            courseByCourse: { course_name: { _in: $courses } }\n          }\n        }\n      }\n    ) {\n      username\n      id\n      __typename\n    }\n    interactions: useinfo(\n      limit: $limit\n      distinct_on: [timestamp, event]\n      order_by: { timestamp: desc, event: asc }\n      where: {\n        _and: {\n          timestamp: { _gte: $timeFrom, _lte: $timeTo }\n          course: { course_name: { _in: $courses } }\n          sid: { _in: $usernames }\n        }\n      }\n    ) {\n      act\n      id\n      event\n      div_id\n      timestamp\n      question {\n        chapter\n        subchapter\n      }\n      course {\n        course_name\n        __typename\n      }\n      user {\n        username\n        first_name\n        last_name\n        __typename\n      }\n      __typename\n    }\n  }\n"]);return ae=function(){return e},e}var ie=p()(ae()),oe={name:"LastUserInteraction",components:{DashboardComponent:T},data:function(){var e=this;return{shouldGoLive:!1,interactions:[],instructors:[],pagination:{rowsPerPage:20},columns:[{name:"name",label:"Étudiant",field:function(e){var t=e.user;return"".concat(t.first_name," ").concat(t.last_name)},sortable:!0},{name:"id",label:"Event ID",field:"id",sortable:!0},{name:"event",label:"Event type",field:"event",sortable:!0},{name:"act",label:"Action",field:function(e){var t=e.act;return t.length>40?t.substring(0,40)+" ...":t},sortable:!0},{name:"div_id",label:"DivID",field:"div_id",sortable:!0},{name:"timestamp",label:"Timestamp",field:"timestamp",format:function(t){return x["a"].formatDate(t,e.$store.state.config.dateFormatPrecise)},sortable:!0}]}},computed:re({},Object(E["c"])(["dataFilters"]),{},Object(E["c"])("dataFilters",["timeRange","courses"]),{},Object(E["b"])("dataFilters",["timeRangeString","selectedStudents"]),{courseName:function(){return this.$route.params.courseName}}),watch:{shouldGoLive:function(e){e?this.$apollo.queries.lastInteractions.startPolling(1e4+5e3*this.selectedStudents.length/20):this.$apollo.queries.lastInteractions.stopPolling()}},apollo:{lastInteractions:{query:ie,variables:function(){return{courses:this.courses,usernames:this.selectedStudents.map((function(e){return e.username})),timeFrom:this.timeRange.from.toISOString(),timeTo:this.timeRange.to.toISOString(),limit:300}},debounce:1e3,result:function(e){var t=this,n=e.data,r=e.loading,a=e.error;this.loading=r,r||a||(this.instructors=n.instructors&&n.instructors.map((function(e){return e.username}))||[],this.interactions=n.interactions.filter((function(e){return-1===t.instructors.indexOf(e.user.username)})).filter((function(e){return 0===t.dataFilters.chapters.length||t.dataFilters.chapters.some((function(t){var n="page"===e.event&&-1!==e.div_id.indexOf(t.chapter_name)||e.question&&e.question.chapter===t.chapter_name;return n}))})).filter((function(e){return 0===t.dataFilters.subChapters.length||t.dataFilters.subChapters.some((function(t){var n="page"===e.event&&-1!==e.div_id.indexOf(t.name)||"page"!==e.event&&e.question&&e.question.subchapter===t.name;return n}))})).map((function(e){return e.div_id="page"===e.event?e.div_id.split("/").splice(-2).join("/"):e.div_id,e})))}}}},se=oe,ce=n("8f8e"),ue=n("58a8"),le=Object(_["a"])(se,ee,te,!1,null,null,null),me=le.exports;function de(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function ge(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?de(n,!0).forEach((function(t){o()(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):de(n).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}y()(le,"components",{QTable:A["a"],QCheckbox:ce["a"],QList:$["a"],QItem:C["a"],QItemSection:P["a"],QBadge:ue["a"]});var pe={components:{IndividualMetrics:G,LiveConnectedStudents:Y,LastUserInteraction:me},computed:ge({},Object(E["c"])("dataFilters",["courses"]),{showTitle:function(){return"on"===this.$route.query.title||!1}}),data:function(){return{since:{days:0,hours:3}}}},fe=pe,be=Object(_["a"])(fe,r,a,!1,null,null,null);t["default"]=be.exports}}]);