(window["webpackJsonp"]=window["webpackJsonp"]||[]).push([[5],{"7a5f":function(t,e,a){"use strict";a.r(e);var n=function(){var t=this,e=t.$createElement,a=t._self._c||e;return a("div",[t._e(),t.isLoading?a("div",[t._v("Loading data ...")]):t._l(t.users,(function(e){return a("q-card",{key:e.id,staticClass:"my-card bg-grey-1 q-my-md",attrs:{flat:"",bordered:""}},[a("q-card-section",[a("div",{staticClass:"row items-center no-wrap"},[a("div",{staticClass:"col"},[a("div",{staticClass:"text-h6"},[t._v("\n            "+t._s(e.lastName)+" "+t._s(e.firstName)+" ("+t._s(e.username)+" /\n            "+t._s(e.id)+" )\n          ")]),a("div",{staticClass:"text-subtitle2"},[t._v("\n            "+t._s(e.codes[0]&&e.codes[0].timestamp)+"\n          ")])]),a("div",{staticClass:"col-auto"},[a("q-btn",{attrs:{color:"grey-7",round:"",flat:"",icon:"more_vert"}},[a("q-menu",{attrs:{cover:"","auto-close":""}},[a("q-list",[a("q-item",{attrs:{clickable:""}},[a("q-item-section",[t._v("Remove Card")])],1),a("q-item",{attrs:{clickable:""}},[a("q-item-section",[t._v("Send Feedback")])],1),a("q-item",{attrs:{clickable:""}},[a("q-item-section",[t._v("Share")])],1)],1)],1)],1)],1)])]),a("q-card-section",[a("tj-editor",{attrs:{initialCode:t.getLastCodeByUser(e),width:"100%",height:"500",autorun:t.autoRunCodes&&!t.avoidAutorun(t.getLastCodeByUser(e))}})],1),a("q-separator"),a("q-card-actions",[a("q-btn",{attrs:{flat:""}},[t._v("Comment")]),a("q-btn",{attrs:{flat:""}},[t._v("Grade")]),a("q-btn",{attrs:{flat:""}},[t._v("Details")]),a("q-btn",{attrs:{flat:"",to:{name:"codeHistory",params:{acid:e&&e.codes[0]&&e.codes[0].acid,username:e&&e.username}}}},[t._v("Code History")])],1)],1)}))],2)},s=[],r=a("d624"),o=a.n(r),i=(a("4917"),a("9530")),c=a.n(i),d=a("77be");function u(){var t=o()(['\n        query lastCodeByAcidAndCourse(\n          $coursePattern: String!\n          $acid: String!\n          $nbCodes: Int = 1\n        ) {\n          users: auth_user(\n            where: {\n              active: { _eq: "T" }\n              course: { course_name: { _like: $coursePattern } }\n            }\n            order_by: { last_name: asc, first_name: asc }\n          ) {\n            username\n            firstName: first_name\n            lastName: last_name\n            id\n            codes(\n              where: { acid: { _eq: $acid } }\n              order_by: { timestamp: desc }\n              limit: $nbCodes\n            ) {\n              acid\n              timestamp\n              code\n              course {\n                course_name\n                __typename\n              }\n              __typename\n            }\n            __typename\n          }\n        }\n      ']);return u=function(){return t},t}var l={components:{"tj-editor":d["a"]},data:function(){return{users:[],isLoading:!0,autoRunCodes:"off"!==this.$route.query.autorun}},methods:{runAllPrograms:function(){},getLastCodeByUser:function(t){return t&&t.codes[0]&&t.codes[0].code||"# code loading ..."},avoidAutorun:function(t){var e=t.match(/input\s*\(/);return e&&e.length>0}},apollo:{lastCodeByAcidAndCourse:{query:c()(u()),variables:function(){return{coursePattern:this.$route.params.courseName,acid:this.$route.params.acid}},result:function(t){var e=t.data,a=t.loading;this.users=e.users,this.isLoading=a}}}},m=l,_=a("2877"),v=a("eebe"),f=a.n(v),b=a("9c40"),q=a("f09f"),C=a("a370"),p=a("4e73"),y=a("1c1c"),h=a("66e5"),g=a("4074"),w=a("eb85"),$=a("4b7e"),Q=Object(_["a"])(m,n,s,!1,null,null,null);e["default"]=Q.exports;f()(Q,"components",{QBtn:b["a"],QCard:q["a"],QCardSection:C["a"],QMenu:p["a"],QList:y["a"],QItem:h["a"],QItemSection:g["a"],QSeparator:w["a"],QCardActions:$["a"]})}}]);