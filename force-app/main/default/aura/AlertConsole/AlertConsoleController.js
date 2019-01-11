({
	doInit : function(component, event, helper) {
		helper.doInit(component,event, helper);
	},
    closeModal: function(component, event, helper) {
      // for Hide/Close Modal,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
   },
})