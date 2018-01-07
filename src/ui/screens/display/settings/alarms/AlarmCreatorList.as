package ui.screens.display.settings.alarms
{
	import databaseclasses.AlertType;
	import databaseclasses.BgReading;
	import databaseclasses.BlueToothDevice;
	import databaseclasses.CommonSettings;
	import databaseclasses.Database;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.GroupedList;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.RelativePosition;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Sprite;
	import starling.events.Event;
	
	import ui.screens.data.AlarmNavigatorData;
	import ui.screens.display.LayoutFactory;
	
	import utilities.DeviceInfo;
	import utilities.MathHelper;
	
	[ResourceBundle("alarmsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class AlarmCreatorList extends GroupedList 
	{
		/* Constants */
		private static const TIME_24_HOURS:int = 24 * 60 * 60 * 1000;
		private static const TIME_1_MINUTE:int = 60 * 1000;
		public static const CANCEL:String = "cancel";
		public static const MODE_ADD:String = "add";
		public static const MODE_EDIT:String = "edit";
		public static const SAVE_EDIT:String = "saveEdit";
		public static const SAVE_ADD:String = "saveAdd";
		
		/* Display Objects */
		private var startTime:DateTimeSpinner;
		private var endTime:DateTimeSpinner;
		private var valueStepper:NumericStepper;
		private var saveAlarm:Button;
		private var cancelAlarm:Button;
		private var alertTypeList:PickerList;
		private var alertCreator:AlertCustomizerList;
		private var alertCreatorCallout:Callout;
		private var positionHelper:Sprite;
		private var actionButtonsContainer:LayoutGroup;
		
		/* Properties */
		private var mode:String;
		private var alarmData:Object;
		private var headerLabelValue:String;
		private var nowDate:Date;
		private var startDate:Date;
		private var endDate:Date;
		private var alarmValue:Number;
		private var alertTypeValue:String;
		private var selectedAlertTypeIndex:int;
		private var hideValue:Boolean = false;
		private var valueLabelValue:String;
		private var minimumStepperValue:Number;
		private var maximumStepperValue:Number;
		private var valueStepperStep:Number;
		
		public function AlarmCreatorList(alarmData:Object, mode:String)
		{
			super();
			
			this.alarmData = alarmData;
			this.mode = mode;
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialState();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			layoutData = new VerticalLayoutData( 100 );
			width = 300;
		}
		
		private function setupInitialState(glucoseUnit:String = null):void
		{
			if ((alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_PHONE_MUTED && alarmData.alarmID == CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT) ||
				(alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY && alarmData.alarmID == CommonSettings.COMMON_SETTING_BATTERY_ALERT))
					hideValue = true;
					
			if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE)
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"bg_value_label");
				valueStepperStep = 1;
				minimumStepperValue = 45;
				maximumStepperValue = 600;
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
				{
					valueStepperStep = 0.1;
					minimumStepperValue = Math.round(((BgReading.mgdlToMmol((minimumStepperValue))) * 10)) / 10;
					maximumStepperValue = Math.round(((BgReading.mgdlToMmol((maximumStepperValue))) * 10)) / 10;
				}
			}
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_CALIBRATION)
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"calibration_value_label");
				valueStepperStep = 1;
				minimumStepperValue = 1;
				maximumStepperValue = 168;
			}
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_MISSED_READING)
			{
				valueLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"missed_readings_value_label");
				valueStepperStep = 5;
				minimumStepperValue = 10;
				maximumStepperValue = 999;
			}
			
			nowDate = new Date();
			if (mode == MODE_ADD)
			{
				headerLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"add_alarm_title");
				startDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 10, 0, 0, 0);
				endDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, 21, 00, 0, 0);
				alertTypeValue = "";
				if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_VERY_HIGH_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_HIGH_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_LOW_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_GLUCOSE && alarmData.alarmID == CommonSettings.COMMON_SETTING_VERY_LOW_ALERT)
				{
					alarmValue = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						alarmValue = Math.round(((BgReading.mgdlToMmol((alarmValue))) * 10)) / 10;
				}
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_CALIBRATION && alarmData.alarmID == CommonSettings.COMMON_SETTING_CALIBRATION_REQUEST_ALERT)
					alarmValue = 12;
				else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_MISSED_READING && alarmData.alarmID == CommonSettings.COMMON_SETTING_MISSED_READING_ALERT)
					alarmValue = 15;
			}
			else
			{
				headerLabelValue = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"edit_alarm_title");
				startDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, Number(alarmData.startHour), Number(alarmData.startMinutes), 0, 0);
				endDate = new Date (nowDate.fullYear, nowDate.month, nowDate.date, Number(alarmData.endHour), Number(alarmData.endMinutes), 0, 0);
				alarmValue = Number(alarmData.value);
				alertTypeValue = alarmData.alertType;
			}
		}
		
		private function setupContent():void
		{
			/* Time Selectors */
			startTime = new DateTimeSpinner();
			startTime.editingMode = DateTimeMode.TIME;
			startTime.value = startDate;
			startTime.height = 35;
			startTime.pivotX = 3;
			startTime.addEventListener(Event.CHANGE, onStartTimeChange);
			
			endTime = new DateTimeSpinner();
			endTime.editingMode = DateTimeMode.TIME;
			endTime.value = endDate;
			endTime.height = 35;
			endTime.pivotX = 3;
			endTime.addEventListener(Event.CHANGE, onEndTimeChange);
			
			/* Value Control */
			valueStepper = LayoutFactory.createNumericStepper(minimumStepperValue, maximumStepperValue, alarmValue);
			valueStepper.step = valueStepperStep;
			valueStepper.pivotX = -10;
			
			/* Alert Types List */
			alertTypeList = LayoutFactory.createPickerList();
			alertTypeList.pivotX = -3;
			
			var alertTypeDataProvider:ArrayCollection = new ArrayCollection();
			alertTypeDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"new_alert_label") } );
			
			var alertTypesData:Array = Database.getAlertTypesList();
			var numAlertTypes:uint = alertTypesData.length;
			selectedAlertTypeIndex = -1;
			for (var i:int = 0; i < numAlertTypes; i++) 
			{
				var alertName:String = (alertTypesData[i] as AlertType).alarmName;
				
				if (alertName != "null" && alertName != "No Alert")
				{
					alertTypeDataProvider.push( { label: alertName } );
					
					if (alertName == alertTypeValue)
						selectedAlertTypeIndex = alertTypeDataProvider.length - 1;
				}
			}
			
			var alertTypeListPopup:DropDownPopUpContentManager = new DropDownPopUpContentManager();
			alertTypeListPopup.primaryDirection = RelativePosition.TOP;
			alertTypeList.popUpContentManager = alertTypeListPopup;
			alertTypeList.dataProvider = alertTypeDataProvider;
			alertTypeList.prompt = ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"select_alert_prompt");
			alertTypeList.selectedIndex = selectedAlertTypeIndex;
			alertTypeList.addEventListener(Event.CHANGE, onAlertListChange);
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			actionButtonsContainer.pivotX = -3;
			
			cancelAlarm = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.cancelTexture);
			cancelAlarm.addEventListener(Event.TRIGGERED, onCancelAlarm);
			actionButtonsContainer.addChild(cancelAlarm);
			
			saveAlarm = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"save_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.saveTexture);
			saveAlarm.addEventListener(Event.TRIGGERED, onSave);
			actionButtonsContainer.addChild(saveAlarm);
			
			/* Data */
			var screenDataContent:Array = [];
			
			var infoSection:Object = {};
			infoSection.header = { label: headerLabelValue };
			
			var infoSectionChildren:Array = [];
			
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"start_time_label"), accessory: startTime });
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"end_time_label"), accessory: endTime });
			if (!hideValue)
				infoSectionChildren.push({ label: valueLabelValue, accessory: valueStepper });
			infoSectionChildren.push({ label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"alert_type_label"), accessory: alertTypeList });
			infoSectionChildren.push({ label: "", accessory: actionButtonsContainer });
			
			infoSection.children = infoSectionChildren;
			screenDataContent.push(infoSection);
			
			dataProvider = new HierarchicalCollection(screenDataContent);
			
			itemRendererFactory = function():IGroupedListItemRenderer
			{
				var itemRenderer:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.iconSourceField = "accessory";
				itemRenderer.height = 50;
				itemRenderer.paddingLeft = -5;
				
				return itemRenderer;
			};
		}
		
		private function refreshAlertTypeList(newAlertName:String):void
		{
			alertTypeList.removeEventListener(Event.CHANGE, onAlertListChange);
			
			var alertTypeDataProvider:ArrayCollection = new ArrayCollection();
			alertTypeDataProvider.push( { label: ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"new_alert_label") } );
			
			var alertTypesData:Array = Database.getAlertTypesList();
			var numAlertTypes:uint = alertTypesData.length;
			for (var i:int = 0; i < numAlertTypes; i++) 
			{
				var alertName:String = (alertTypesData[i] as AlertType).alarmName;
				
				if (alertName != "null" && alertName != "No Alert")
				{
					alertTypeDataProvider.push( { label: alertName } );
					
					if (alertName == newAlertName)
						selectedAlertTypeIndex = alertTypeDataProvider.length - 1;
				}
			}
			
			alertTypeList.dataProvider = null;
			alertTypeList.dataProvider = alertTypeDataProvider;
			alertTypeList.selectedIndex = selectedAlertTypeIndex;
			alertTypeList.addEventListener(Event.CHANGE, onAlertListChange);
		}
		
		private function setupCalloutPosition():void
		{
			positionHelper = new Sprite();
			positionHelper.x = this.width / 2;
			positionHelper.y = -35;
			addChild(positionHelper);
		}
		
		private function onAlertListChange(e:Event):void
		{
			if (alertTypeList.selectedIndex == -1)
				return;
			
			saveAlarm.isEnabled = true;
			
			var selectedItemLabel:String = alertTypeList.selectedItem.label;
			if (selectedItemLabel == ModelLocator.resourceManagerInstance.getString('alarmsettingsscreen',"new_alert_label"))
			{
				alertTypeList.selectedIndex = selectedAlertTypeIndex;
				
				alertCreator = new AlertCustomizerList(null);
				alertCreator.addEventListener(Event.COMPLETE, onAlertCreatorClose);
				alertCreatorCallout = new Callout();
				alertCreatorCallout.content = alertCreator;
				if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_4_4S)
					alertCreatorCallout.padding = 18;
				else
				{
					if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_5_5S_5C_SE)
						alertCreatorCallout.padding = 18;
					
					setupCalloutPosition();
					alertCreatorCallout.origin = positionHelper;
				}
				PopUpManager.addPopUp(alertCreatorCallout, true, false);
			}
			else
				selectedAlertTypeIndex = alertTypeList.selectedIndex;
		}
		
		private function onAlertCreatorClose(e:Event):void
		{
			if (e.data != null)
				refreshAlertTypeList(e.data.newAlertName);
			
			alertCreatorCallout.close(true);
		}
		
		/**
		 * Event Handlers
		 */
		private function onSave(e:Event):void
		{
			/* End Time */
			alarmData.endHour = endTime.value.hours;
			alarmData.endMinutes = endTime.value.minutes;
				
			alarmData.endTimeOutput = MathHelper.formatNumberToString(alarmData.endHour) + ":" + MathHelper.formatNumberToString(alarmData.endMinutes);
			alarmData.endTimeStamp = (Number(alarmData.endHour) * 60 * 60 * 1000) + (Number(alarmData.endMinutes) * 60 * 1000);
				
			/* Start Time */
			alarmData.startHour = startTime.value.hours;
			alarmData.startMinutes = startTime.value.minutes;
			
			alarmData.startTimeOutput = MathHelper.formatNumberToString(alarmData.startHour) + ":" + MathHelper.formatNumberToString(alarmData.startMinutes);
			alarmData.startTimeStamp = (Number(alarmData.startHour) * 60 * 60 * 1000) + (Number(alarmData.startMinutes) * 60 * 1000);
				
			/* Value */
			if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_PHONE_MUTED && alarmData.alarmID == CommonSettings.COMMON_SETTING_PHONE_MUTED_ALERT)
				alarmData.value = 0;
			else if (alarmData.alarmType == AlarmNavigatorData.ALARM_TYPE_TRANSMITTER_LOW_BATTERY && alarmData.alarmID == CommonSettings.COMMON_SETTING_BATTERY_ALERT)
			{
				if (BlueToothDevice.isDexcomG5())
					alarmData.value = 300;
				else if (BlueToothDevice.isDexcomG4())
					alarmData.value = 210;
				else if (BlueToothDevice.isBluKon())
					alarmData.value = 5;
			}
			else
			{
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
					alarmData.value = Math.round(BgReading.mmolToMgdl(valueStepper.value));
				else
					alarmData.value = valueStepper.value;
			}
				
			/* Alert Type */
			alarmData.alertType = alertTypeList.selectedItem.label;
			
			if (mode == MODE_EDIT) dispatchEventWith(SAVE_EDIT, false, alarmData);
			else dispatchEventWith(SAVE_ADD, false, alarmData);
		}
		
		private function onCancelAlarm(e:Event):void
		{
			dispatchEventWith(CANCEL);
		}
		
		private function onStartTimeChange(e:Event):void
		{
			var startTimestamp:Number = startTime.value.valueOf();
			var endDateTimestamp:Number = endTime.value.valueOf();
			
			if (startTimestamp + TIME_1_MINUTE > endDateTimestamp)
				endTime.value = new Date(startTimestamp + TIME_1_MINUTE);
		}
		
		private function onEndTimeChange(e:Event):void
		{
			var endDateTimestamp:Number = endTime.value.valueOf();
			var startTimestamp:Number = startTime.value.valueOf();
			
			if (endDateTimestamp <= startTimestamp)
				startTime.value = new Date(endDateTimestamp - TIME_1_MINUTE);
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			if (selectedAlertTypeIndex == -1)
				saveAlarm.isEnabled = false;
			
			super.draw();
		}
		
		override public function dispose():void
		{	
			if (startTime != null)
			{
				startTime.dispose();
				startTime = null;
			}
			
			if (endTime != null)
			{
				endTime.dispose();
				endTime = null;
			}
			
			if (valueStepper != null)
			{
				valueStepper.dispose();
				valueStepper = null;
			}
			
			if (saveAlarm != null)
			{
				actionButtonsContainer.removeChild(saveAlarm);
				saveAlarm.dispose();
				saveAlarm = null;
			}
			
			if (cancelAlarm != null)
			{
				actionButtonsContainer.removeChild(cancelAlarm);
				cancelAlarm.dispose();
				cancelAlarm = null;
			}
			
			if (alertTypeList != null)
			{
				alertTypeList.dispose();
				alertTypeList = null;
			}
			
			if (actionButtonsContainer != null)
			{
				actionButtonsContainer.dispose();
				actionButtonsContainer = null;
			}
			
			if (alertCreator != null)
			{
				alertCreator.dispose();
				alertCreator = null;
			}
			
			if (alertCreatorCallout != null)
			{
				alertCreatorCallout.dispose();
				alertCreatorCallout = null;
			}
			
			if (positionHelper != null)
			{
				removeChild(positionHelper);
				positionHelper.dispose();
				positionHelper = null;
			}
			
			super.dispose();
		}
	}
}