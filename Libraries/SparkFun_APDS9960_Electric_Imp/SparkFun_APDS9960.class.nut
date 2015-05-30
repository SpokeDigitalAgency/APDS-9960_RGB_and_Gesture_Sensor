class SparkFun_APDS9960
{
    /**
     * @brief   Electric Imp library for the SparkFun APDS-9960 breakout board
     * @author  Shawn Hymel (SparkFun Electronics) (original Arduino code)
     * @author  Eric Svensson (Spoke Digital Agency AB) (port to Electric Imp)
     *
     * @copyright   This code is public domain but you buy me a beer if you use
     * this and we meet someday (Beerware license).
     *
     * This library interfaces the Avago APDS-9960 to Electric Imp over I2C. The
     * library relies on the Electric Imp i2c API. To use the library, first
     * configure an i2c port using the Electric Imp i2c API, then instantiate a
     * SparkFun_APDS9960 object with the i2c port as argument, call init(), and
     * call the appropriate functions.
     *
     * APDS-9960 current draw tests (default parameters):
     *   Off:                   1mA
     *   Waiting for gesture:   14mA
     *   Gesture in progress:   35mA
     */

    _i2c = null;
    
    constructor (impI2Cbus)
    {
        _i2c = impI2Cbus;
    }
    
    gesture_ud_delta_ = 0;
    gesture_lr_delta_ = 0;
    gesture_ud_count_ = 0;
    gesture_lr_count_ = 0;
    gesture_near_count_ = 0;
    gesture_far_count_ = 0;
    gesture_state_ = 0;
    gesture_motion_ = 0; // DIR_NONE
    
    /* The APDS-9960 datasheet specifies a 7-bit i2c address 0x39. The Electric
     * Imp i2c API requires an 8-bit i2c address, so 0x39 needs to be shifted by
     * one bit to the left, like so: 0x39 << 1 = 0x72.
     */
    APDS9960_ADDR = 0x72;
    
    // Gesture parameters
    static GESTURE_THRESHOLD_OUT = 10;
    static GESTURE_SENSITIVITY_1 = 50;
    static GESTURE_SENSITIVITY_2 = 20;
    
    // Error code for returned values
    static ERROR = 0xFF;
    
    // Acceptable device IDs
    static APDS9960_ID_1 = 0xAB;
    static APDS9960_ID_2 = 0x9C;
    
    // Misc parameters
    static FIFO_PAUSE_TIME = 30      // Wait period (ms) between FIFO reads
    
    // APDS-9960 register addresses
    static APDS9960_ENABLE = "\x80";
    static APDS9960_ATIME = "\x81";
    static APDS9960_WTIME = "\x83";
    static APDS9960_AILTL = "\x84";
    static APDS9960_AILTH = "\x85";
    static APDS9960_AIHTL = "\x86";
    static APDS9960_AIHTH = "\x87";
    static APDS9960_PILT = "\x89";
    static APDS9960_PIHT = "\x8B";
    static APDS9960_PERS = "\x8C";
    static APDS9960_CONFIG1 = "\x8D";
    static APDS9960_PPULSE = "\x8E";
    static APDS9960_CONTROL = "\x8F";
    static APDS9960_CONFIG2 = "\x90";
    static APDS9960_ID = "\x92";
    static APDS9960_STATUS = "\x93";
    static APDS9960_CDATAL = "\x94";
    static APDS9960_CDATAH = "\x95";
    static APDS9960_RDATAL = "\x96";
    static APDS9960_RDATAH = "\x97";
    static APDS9960_GDATAL = "\x98";
    static APDS9960_GDATAH = "\x99";
    static APDS9960_BDATAL = "\x9A";
    static APDS9960_BDATAH = "\x9B";
    static APDS9960_PDATA = "\x9C";
    static APDS9960_POFFSET_UR = "\x9D";
    static APDS9960_POFFSET_DL = "\x9E";
    static APDS9960_CONFIG3 = "\x9F";
    static APDS9960_GPENTH = "\xA0";
    static APDS9960_GEXTH = "\xA1";
    static APDS9960_GCONF1 = "\xA2";
    static APDS9960_GCONF2 = "\xA3";
    static APDS9960_GOFFSET_U = "\xA4";
    static APDS9960_GOFFSET_D = "\xA5";
    static APDS9960_GOFFSET_L = "\xA7";
    static APDS9960_GOFFSET_R = "\xA9";
    static APDS9960_GPULSE = "\xA6";
    static APDS9960_GCONF3 = "\xAA";
    static APDS9960_GCONF4 = "\xAB";
    static APDS9960_GFLVL = "\xAE";
    static APDS9960_GSTATUS = "\xAF";
    static APDS9960_IFORCE = "\xE4";
    static APDS9960_PICLEAR = "\xE5";
    static APDS9960_CICLEAR = "\xE6";
    static APDS9960_AICLEAR = "\xE7";
    static APDS9960_GFIFO_U = "\xFC";
    static APDS9960_GFIFO_D = "\xFD";
    static APDS9960_GFIFO_L = "\xFE";
    static APDS9960_GFIFO_R = "\xFF";
    
    /* Bit fields */
    static APDS9960_PON = 0x01;
    static APDS9960_AEN = 0x02;
    static APDS9960_PEN = 0x04;
    static APDS9960_WEN = 0x08;
    static APSD9960_AIEN = 0x10;
    static APDS9960_PIEN = 0x20;
    static APDS9960_GEN = 0x40;
    static APDS9960_GVALID = 0x01;
    
    // On/Off definitions
    static OFF = 0;
    static ON = 1;
    
    // Acceptable parameters for setMode
    static POWER = 0;
    static AMBIENT_LIGHT = 1;
    static PROXIMITY = 2;
    static WAIT = 3;
    static AMBIENT_LIGHT_INT = 4;
    static PROXIMITY_INT = 5;
    static GESTURE = 6;
    static ALL = 7;
    
    // LED Drive values
    static LED_DRIVE_100MA = 0;
    static LED_DRIVE_50MA = 1;
    static LED_DRIVE_25MA = 2;
    static LED_DRIVE_12_5MA = 3;
    
    // Proximity Gain (PGAIN) values
    static PGAIN_1X = 0;
    static PGAIN_2X = 1;
    static PGAIN_4X = 2;
    static PGAIN_8X = 3;
    
    // ALS Gain (AGAIN) values
    static AGAIN_1X = 0;
    static AGAIN_4X = 1;
    static AGAIN_16X = 2;
    static AGAIN_64X = 3;
    
    // Gesture Gain (GGAIN) values
    static GGAIN_1X = 0;
    static GGAIN_2X = 1;
    static GGAIN_4X = 2;
    static GGAIN_8X = 3;
    
    // LED Boost values
    static LED_BOOST_100 = 0;
    static LED_BOOST_150 = 1;
    static LED_BOOST_200 = 2;
    static LED_BOOST_300 = 3;
    
    // Gesture wait time values
    static GWTIME_0MS = 0;
    static GWTIME_2_8MS = 1;
    static GWTIME_5_6MS = 2;
    static GWTIME_8_4MS = 3;
    static GWTIME_14_0MS = 4;
    static GWTIME_22_4MS = 5;
    static GWTIME_30_8MS = 6;
    static GWTIME_39_2MS = 7;
    
    // Default values
    static DEFAULT_ATIME = 219;     // 103ms
    static DEFAULT_WTIME = 246;     // 27ms
    static DEFAULT_PROX_PPULSE = 0x87;    // 16us, 8 pulses
    static DEFAULT_GESTURE_PPULSE = 0x89;    // 16us, 10 pulses
    static DEFAULT_POFFSET_UR = 0;       // 0 offset
    static DEFAULT_POFFSET_DL = 0;       // 0 offset      
    static DEFAULT_CONFIG1 = 0x60;    // No 12x wait (WTIME) factor
    static DEFAULT_LDRIVE = 0; // LED_DRIVE_100MA
    static DEFAULT_PGAIN = 2; // PGAIN_4X
    static DEFAULT_AGAIN = 1; // AGAIN_4X
    static DEFAULT_PILT = 0;       // Low proximity threshold
    static DEFAULT_PIHT = 50;      // High proximity threshold
    static DEFAULT_AILT = 0xFFFF;  // Force interrupt for calibration
    static DEFAULT_AIHT = 0;
    static DEFAULT_PERS = 0x11;    // 2 consecutive prox or ALS for int.
    static DEFAULT_CONFIG2 = 0x01;    // No saturation interrupts or LED boost  
    static DEFAULT_CONFIG3 = 0;       // Enable all photodiodes, no SAI
    static DEFAULT_GPENTH = 40;      // Threshold for entering gesture mode
    static DEFAULT_GEXTH = 30;      // Threshold for exiting gesture mode    
    static DEFAULT_GCONF1 = 0x40;    // 4 gesture events for int., 1 for exit
    static DEFAULT_GGAIN = 2; // GGAIN_4X
    static DEFAULT_GLDRIVE = 0; // LED_DRIVE_100MA
    static DEFAULT_GWTIME = 1; // GWTIME_2_8MS
    static DEFAULT_GOFFSET = 0;       // No offset scaling for gesture mode
    static DEFAULT_GPULSE = 0xC9;    // 32us, 10 pulses
    static DEFAULT_GCONF3 = 0;       // All photodiodes active during gesture
    static DEFAULT_GIEN = 0;       // Disable gesture interrupts

    static DIR_NONE = 0;
    static DIR_LEFT = 1;
    static DIR_RIGHT = 2;
    static DIR_UP = 3;
    static DIR_DOWN = 4;
    static DIR_NEAR = 5;
    static DIR_FAR = 6;
    static DIR_ALL = 7;

    static NA_STATE = 0;
    static NEAR_STATE = 1;
    static FAR_STATE = 2;
    static ALL_STATE = 3;

    gesture_data_ = {
        u_data = array(32),
        d_data = array(32),
        l_data = array(32),
        r_data = array(32),
        index = null,
        total_gestures = null,
        in_threshold = null,
        out_threshold = null
    };

    // Helper function for reading one byte on the i2c interface.
    function readi2cbyte(subaddr)
    {
        return _i2c.read(APDS9960_ADDR, subaddr, 1)[0];
    }

    function readi2cblock(subaddr, length)
    {
        return _i2c.read(APDS9960_ADDR, subaddr, length);
    } 
    
    function writei2c(subaddr, data)
    {
        return ( 0 == _i2c.write(APDS9960_ADDR, subaddr + data.tochar()) );
    }
    
    /**
     * @brief Configures I2C communications and initializes registers to defaults
     *
     * @return True if initialized successfully. False otherwise.
     */
    function init()
    {
        /* Read ID register and check against known values for APDS-9960 */
        local id = readi2cbyte(APDS9960_ID);
    
        if ( !(id == APDS9960_ID_1 || id == APDS9960_ID_2) ) {
            return false;
        }
        
        /* Set ENABLE register to 0 (disable all features) */
        if( !setMode(ALL, OFF) ) {
            return false;
        }
    
        /* Set default values for ambient light and proximity registers */
        if( !writei2c(APDS9960_ATIME, DEFAULT_ATIME) ) {
            return false;
        }
        if( !writei2c(APDS9960_WTIME, DEFAULT_WTIME) ) {
            return false;
        }
        if( !writei2c(APDS9960_PPULSE, DEFAULT_PROX_PPULSE) ) {
            return false;
        }
        if( !writei2c(APDS9960_POFFSET_UR, DEFAULT_POFFSET_UR) ) {
            return false;
        }
        if( !writei2c(APDS9960_POFFSET_DL, DEFAULT_POFFSET_DL) ) {
            return false;
        }
        if( !writei2c(APDS9960_CONFIG1, DEFAULT_CONFIG1) ) {
            return false;
        }
        if( !setLEDDrive(DEFAULT_LDRIVE) ) {
            return false;
        }
        if( !setProximityGain(DEFAULT_PGAIN) ) {
            return false;
        }
        if( !setAmbientLightGain(DEFAULT_AGAIN) ) {
            return false;
        }
        if( !setProxIntLowThresh(DEFAULT_PILT) ) {
            return false;
        }
        if( !setProxIntHighThresh(DEFAULT_PIHT) ) {
            return false;
        }
        if( !setLightIntLowThreshold(DEFAULT_AILT) ) {
            return false;
        }
        if( !setLightIntHighThreshold(DEFAULT_AIHT) ) {
            return false;
        }
        if( !writei2c(APDS9960_PERS, DEFAULT_PERS) ) {
            return false;
        }
        if( !writei2c(APDS9960_CONFIG2, DEFAULT_CONFIG2) ) {
            return false;
        }
        if( !writei2c(APDS9960_CONFIG3, DEFAULT_CONFIG3) ) {
            return false;
        }
    
        // Set default values for gesture sense registers
        if( !setGestureEnterThresh(DEFAULT_GPENTH) ) {
            return false;
        }
        if( !setGestureExitThresh(DEFAULT_GEXTH) ) {
            return false;
        }
        if( !writei2c(APDS9960_GCONF1, DEFAULT_GCONF1) ) {
            return false;
        }
        if( !setGestureGain(DEFAULT_GGAIN) ) {
            return false;
        }
        if( !setGestureLEDDrive(DEFAULT_GLDRIVE) ) {
            return false;
        }
        if( !setGestureWaitTime(DEFAULT_GWTIME) ) {
            return false;
        }
        if( !writei2c(APDS9960_GOFFSET_U, DEFAULT_GOFFSET) ) {
            return false;
        }
        if( !writei2c(APDS9960_GOFFSET_D, DEFAULT_GOFFSET) ) {
            return false;
        }
        if( !writei2c(APDS9960_GOFFSET_L, DEFAULT_GOFFSET) ) {
            return false;
        }
        if( !writei2c(APDS9960_GOFFSET_R, DEFAULT_GOFFSET) ) {
            return false;
        }
        if( !writei2c(APDS9960_GPULSE, DEFAULT_GPULSE) ) {
            return false;
        }
        if( !writei2c(APDS9960_GCONF3, DEFAULT_GCONF3) ) {
            return false;
        }
        if( !setGestureIntEnable(DEFAULT_GIEN) ) {
            return false;
        }

        /* Gesture config register dump */
        /*local reg;
        local val;

        for(reg = 0x80; reg <= 0xAF; reg++) {
            if( (reg != 0x82) &&
                (reg != 0x8A) &&
                (reg != 0x91) &&
                (reg != 0xA8) &&
                (reg != 0xAC) &&
                (reg != 0xAD) )
            {
                val = readi2cbyte(reg);
                server.log(reg, HEX);
                server.log(": 0x");
                server.log(val, HEX);
            }
        }

        for(reg = 0xE4; reg <= 0xE7; reg++) {
            val = readi2cbyte(reg);
            server.log(reg, HEX);
            server.log(": 0x");
            server.log(val, HEX);
        }*/

        return true;
    }
    
    /*******************************************************************************
     * Public methods for controlling the APDS-9960
     ******************************************************************************/
    
    /**
     * @brief Reads and returns the contents of the ENABLE register
     *
     * @return Contents of the ENABLE register. 0xFF if error.
     */
    function getMode()
    {
        local enable_value;
    
        // Read current ENABLE register
        if( null == (enable_value = readi2cbyte(APDS9960_ENABLE)) ) {
            return ERROR;
        }
    
        return enable_value;
    }
    
    /**
     * @brief Enables or disables a feature in the APDS-9960
     *
     * @param[in] mode which feature to enable
     * @param[in] enable ON (1) or OFF (0)
     * @return True if operation success. False otherwise.
     */
    function setMode(mode, enable)
    {
        local reg_val;
    
        /* Read current ENABLE register */
        reg_val = getMode();
        if( reg_val == ERROR ) {
            return false;
        }
        
        /* Change bit(s) in ENABLE register */
        enable = enable & 0x01;
        if( mode >= 0 && mode <= 6 ) {
            if (enable) {
                reg_val = reg_val | (1 << mode);
            } else {
                reg_val = reg_val & ~(1 << mode);
            }
        } else if( mode == ALL ) {
            if (enable) {
                reg_val = 0x7F;
            } else {
                reg_val = 0x00;
            }
        }
    
        /* Write value back to ENABLE register */
        if( !writei2c(APDS9960_ENABLE, reg_val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Starts the light (R/G/B/Ambient) sensor on the APDS-9960
     *
     * @param[in] interrupts true to enable hardware interrupt on high or low light
     * @return True if sensor enabled correctly. False on error.
     */
    function enableLightSensor(interrupts)
    {
        
        /* Set default gain, interrupts, enable power, and enable sensor */
        if( !setAmbientLightGain(DEFAULT_AGAIN) ) {
            return false;
        }
        if( interrupts ) {
            if( !setAmbientLightIntEnable(1) ) {
                return false;
            }
        } else {
            if( !setAmbientLightIntEnable(0) ) {
                return false;
            }
        }
        if( !enablePower() ){
            return false;
        }
        if( !setMode(AMBIENT_LIGHT, 1) ) {
            return false;
        }
        
        return true;
    
    }
    
    /**
     * @brief Ends the light sensor on the APDS-9960
     *
     * @return True if sensor disabled correctly. False on error.
     */
    function disableLightSensor()
    {
        if( !setAmbientLightIntEnable(0) ) {
            return false;
        }
        if( !setMode(AMBIENT_LIGHT, 0) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Starts the proximity sensor on the APDS-9960
     *
     * @param[in] interrupts true to enable hardware external interrupt on proximity
     * @return True if sensor enabled correctly. False on error.
     */
    function enableProximitySensor(interrupts)
    {
        /* Set default gain, LED, interrupts, enable power, and enable sensor */
        if( !setProximityGain(DEFAULT_PGAIN) ) {
            return false;
        }
        if( !setLEDDrive(DEFAULT_LDRIVE) ) {
            return false;
        }
        if( interrupts ) {
            if( !setProximityIntEnable(1) ) {
                return false;
            }
        } else {
            if( !setProximityIntEnable(0) ) {
                return false;
            }
        }
        if( !enablePower() ){
            return false;
        }
        if( !setMode(PROXIMITY, 1) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Ends the proximity sensor on the APDS-9960
     *
     * @return True if sensor disabled correctly. False on error.
     */
    function disableProximitySensor()
    {
        if( !setProximityIntEnable(0) ) {
            return false;
        }
        if( !setMode(PROXIMITY, 0) ) {
            return false;
        }
    
        return true;
    }
    
    /**
     * @brief Starts the gesture recognition engine on the APDS-9960
     *
     * @param[in] interrupts true to enable hardware external interrupt on gesture
     * @return True if engine enabled correctly. False on error.
     */
    function enableGestureSensor(interrupts)
    {
        
        /* Enable gesture mode
           Set ENABLE to 0 (power off)
           Set WTIME to 0xFF
           Set AUX to LED_BOOST_300
           Enable PON, WEN, PEN, GEN in ENABLE 
        */
        resetGestureParameters();
        if( !writei2c(APDS9960_WTIME, 0xFF) ) {
            return false;
        }
        if( !writei2c(APDS9960_PPULSE, DEFAULT_GESTURE_PPULSE) ) {
            return false;
        }
        if( !setLEDBoost(LED_BOOST_300) ) {
            return false;
        }
        if( interrupts ) {
            if( !setGestureIntEnable(1) ) {
                return false;
            }
        } else {
            if( !setGestureIntEnable(0) ) {
                return false;
            }
        }
        if( !setGestureMode(1) ) {
            return false;
        }
        if( !enablePower() ){
            return false;
        }
        if( !setMode(WAIT, 1) ) {
            return false;
        }
        if( !setMode(PROXIMITY, 1) ) {
            return false;
        }
        if( !setMode(GESTURE, 1) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Ends the gesture recognition engine on the APDS-9960
     *
     * @return True if engine disabled correctly. False on error.
     */
    function disableGestureSensor()
    {
        resetGestureParameters();
        if( !setGestureIntEnable(0) ) {
            return false;
        }
        if( !setGestureMode(0) ) {
            return false;
        }
        if( !setMode(GESTURE, 0) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Determines if there is a gesture available for reading
     *
     * @return True if gesture available. False otherwise.
     */
    function isGestureAvailable()
    {
        local val;
        
        /* Read value from GSTATUS register */
        if( null == (val = readi2cbyte(APDS9960_GSTATUS)) ) {
            return ERROR;
        }
        
        /* Shift and mask out GVALID bit */
        val = val & APDS9960_GVALID;
        
        /* Return true/false based on GVALID bit */
        if( val == 1) {
            return true;
        } else {
            return false;
        }
    }
    
    /**
     * @brief Processes a gesture event and returns best guessed gesture
     *
     * @return Number corresponding to gesture. -1 on error.
     */
    function readGesture()
    {
        local fifo_level = 0;
        local bytes_read = 0;
        local fifo_data = array(128);
        local gstatus;
        local motion;
        local i;
        
        /* Make sure that power and gesture is on and data is valid */
        if( !isGestureAvailable() || !(getMode() & 0x41) ) {
            return DIR_NONE;
        }
        
        /* Keep looping as long as gesture data is valid */
        while(1) {
        
            /* Wait some time to collect next batch of FIFO data */
            imp.sleep(FIFO_PAUSE_TIME / 1000);
            
            /* Get the contents of the STATUS register. Is data still valid? */
            if( null == (gstatus = readi2cbyte(APDS9960_GSTATUS)) ) {
                return ERROR;
            }

            /* If we have valid data, read in FIFO */
            if( (gstatus & APDS9960_GVALID) == APDS9960_GVALID ) {
            
                /* Read the current FIFO level */
                if( null == (fifo_level = readi2cbyte(APDS9960_GFLVL)) ) {
                    return ERROR;
                }

/*                server.log("FIFO Level: ");
                server.log(fifo_level);*/
    
                /* If there's stuff in the FIFO, read it into our data block */
                if( fifo_level > 0) {
                    fifo_data = readi2cblock(APDS9960_GFIFO_U, (fifo_level * 4))
                    bytes_read = fifo_data.len()

                    if( fifo_data == null ) {
                        return ERROR;
                    }
    
                    /*server.log("FIFO Dump: ");
                    for ( i = 0; i < bytes_read; i++ ) {
                        server.log(fifo_data[i]);
                        server.log(" ");
                    }*/
    
                    /* If at least 1 set of data, sort the data into U/D/L/R */
                    if( bytes_read >= 4 ) {
                        for( i = 0; i < bytes_read; i += 4 ) {
                            gesture_data_.u_data[gesture_data_.index] = fifo_data[i + 0];
                            gesture_data_.d_data[gesture_data_.index] = fifo_data[i + 1];
                            gesture_data_.l_data[gesture_data_.index] = fifo_data[i + 2];
                            gesture_data_.r_data[gesture_data_.index] = fifo_data[i + 3];
                            gesture_data_.index++;
                            gesture_data_.total_gestures++;
                        }

                        /*server.log("Up Data: ");
                        for ( i = 0; i < gesture_data_.total_gestures; i++ ) {
                            server.log(gesture_data_.u_data[i]);
                            server.log(" ");
                        }*/
    
                        /* Filter and process gesture data. Decode near/far state */
                        if( processGestureData() ) {
                            if( decodeGesture() ) {
                                //***TODO: U-Turn Gestures

                                //server.log(gesture_motion_);
                            }
                        }
                        
                        /* Reset data */
                        gesture_data_.index = 0;
                        gesture_data_.total_gestures = 0;
                    }
                }
            } else {
        
                /* Determine best guessed gesture and clean up */
                imp.sleep(FIFO_PAUSE_TIME / 1000);
                decodeGesture();
                motion = gesture_motion_;

                /*server.log("END: ");
                server.log(gesture_motion_);*/

                resetGestureParameters();
                return motion;
            }
        }
    }
    
    /**
     * Turn the APDS-9960 on
     *
     * @return True if operation successful. False otherwise.
     */
    function enablePower()
    {
        if( !setMode(POWER, 1) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * Turn the APDS-9960 off
     *
     * @return True if operation successful. False otherwise.
     */
    function disablePower()
    {
        if( !setMode(POWER, 0) ) {
            return false;
        }
        
        return true;
    }
    
    /*******************************************************************************
     * Ambient light and color sensor controls
     ******************************************************************************/
    
    /**
     * @brief Reads the ambient (clear) light level as a 16-bit value
     *
     * @return value of the light sensor if operation successful. False otherwise.
     */
    function readAmbientLight()
    {
        local val_byte;
        local val = 0;
        
        /* Read value from clear channel, low byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_CDATAL)) ) {
            return false;
        }
        val = val_byte;
        
        /* Read value from clear channel, high byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_CDATAH)) ) {
            return false;
        }
        //val = val + ((uint16_t)val_byte << 8);
        val = val + (val_byte << 8);
        
        return val;
    }
    
    /**
     * @brief Reads the red light level as a 16-bit value
     *
     * @return value of the light sensor if operation successful. False otherwise.
     */
    function readRedLight()
    {
        local val_byte;
        local val = 0;
        
        /* Read value from clear channel, low byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_RDATAL)) ) {
            return false;
        }
        val = val_byte;
        
        /* Read value from clear channel, high byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_RDATAH)) ) {
            return false;
        }
        //val = val + ((uint16_t)val_byte << 8);
        val = val + (val_byte << 8);
        
        return val;
    }
     
    /**
     * @brief Reads the green light level as a 16-bit value
     *
     * @return value of the light sensor if operation successful. False otherwise.
     */
    function readGreenLight()
    {
        local val_byte;
        local val = 0;
        
        /* Read value from clear channel, low byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_GDATAL)) ) {
            return false;
        }
        val = val_byte;
        
        /* Read value from clear channel, high byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_GDATAH)) ) {
            return false;
        }
        //val = val + ((uint16_t)val_byte << 8);
        val = val + (val_byte << 8);
        
        return val;
    }
    
    /**
     * @brief Reads the red light level as a 16-bit value
     *
     * @return value of the light sensor if operation successful. False otherwise.
     */
    function readBlueLight()
    {
        local val_byte;
        local val = 0;
        
        /* Read value from clear channel, low byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_BDATAL)) ) {
            return false;
        }
        val = val_byte;
        
        /* Read value from clear channel, high byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_BDATAH)) ) {
            return false;
        }
        //val = val + ((uint16_t)val_byte << 8);
        val = val + (val_byte << 8);
        
        return val;
    }
    
    /*******************************************************************************
     * Proximity sensor controls
     ******************************************************************************/
    
    /**
     * @brief Reads the proximity level as an 8-bit value
     *
     * @param[out] val value of the proximity sensor.
     * @return True if operation successful. False otherwise.
     */
    function readProximity()
    {
        local val = 0;
        
        /* Read value from proximity data register */
        if( null == (val = readi2cbyte(APDS9960_PDATA)) ) {
            return false;
        }
        
        return val;
    }
    
    /*******************************************************************************
     * High-level gesture controls
     ******************************************************************************/
    
    /**
     * @brief Resets all the parameters in the gesture data member
     */
    function resetGestureParameters()
    {
        gesture_data_.index = 0;
        gesture_data_.total_gestures = 0;
        
        gesture_ud_delta_ = 0;
        gesture_lr_delta_ = 0;
        
        gesture_ud_count_ = 0;
        gesture_lr_count_ = 0;
        
        gesture_near_count_ = 0;
        gesture_far_count_ = 0;
        
        gesture_state_ = 0;
        gesture_motion_ = DIR_NONE;
    }
    
    /**
     * @brief Processes the raw gesture data to determine swipe direction
     *
     * @return True if near or far state seen. False otherwise.
     */
    function processGestureData()
    {
        local u_first = 0;
        local d_first = 0;
        local l_first = 0;
        local r_first = 0;
        local u_last = 0;
        local d_last = 0;
        local l_last = 0;
        local r_last = 0;
        local ud_ratio_first;
        local lr_ratio_first;
        local ud_ratio_last;
        local lr_ratio_last;
        local ud_delta;
        local lr_delta;
        local i;
    
        /* If we have less than 4 total gestures, that's not enough */
        if( gesture_data_.total_gestures <= 4 ) {
            return false;
        }

        /* Check to make sure our data isn't out of bounds */
        if( (gesture_data_.total_gestures <= 32) && 
            (gesture_data_.total_gestures > 0) ) {

            /* Find the first value in U/D/L/R above the threshold */
            for( i = 0; i < gesture_data_.total_gestures; i++ ) {
                if( (gesture_data_.u_data[i] > GESTURE_THRESHOLD_OUT) &&
                    (gesture_data_.d_data[i] > GESTURE_THRESHOLD_OUT) &&
                    (gesture_data_.l_data[i] > GESTURE_THRESHOLD_OUT) &&
                    (gesture_data_.r_data[i] > GESTURE_THRESHOLD_OUT) ) {
                    
                    u_first = gesture_data_.u_data[i];
                    d_first = gesture_data_.d_data[i];
                    l_first = gesture_data_.l_data[i];
                    r_first = gesture_data_.r_data[i];
                    break;
                }
            }
            
            /* If one of the _first values is 0, then there is no good data */
            if( (u_first == 0) || (d_first == 0) || (l_first == 0) || (r_first == 0) ) {
                return false;
            }
            /* Find the last value in U/D/L/R above the threshold */
            for( i = gesture_data_.total_gestures - 1; i >= 0; i-- ) {

                /*server.log(F("Finding last: "));
                server.log(F("U:"));
                server.log(gesture_data_.u_data[i]);
                server.log(F(" D:"));
                server.log(gesture_data_.d_data[i]);
                server.log(F(" L:"));
                server.log(gesture_data_.l_data[i]);
                server.log(F(" R:"));
                server.log(gesture_data_.r_data[i]);*/

                if( (gesture_data_.u_data[i] > GESTURE_THRESHOLD_OUT) &&
                    (gesture_data_.d_data[i] > GESTURE_THRESHOLD_OUT) &&
                    (gesture_data_.l_data[i] > GESTURE_THRESHOLD_OUT) &&
                    (gesture_data_.r_data[i] > GESTURE_THRESHOLD_OUT) ) {
                    
                    u_last = gesture_data_.u_data[i];
                    d_last = gesture_data_.d_data[i];
                    l_last = gesture_data_.l_data[i];
                    r_last = gesture_data_.r_data[i];
                    break;
                }
            }
        }
        
        /* Calculate the first vs. last ratio of up/down and left/right */
        ud_ratio_first = ((u_first - d_first) * 100) / (u_first + d_first);
        lr_ratio_first = ((l_first - r_first) * 100) / (l_first + r_first);
        ud_ratio_last = ((u_last - d_last) * 100) / (u_last + d_last);
        lr_ratio_last = ((l_last - r_last) * 100) / (l_last + r_last);
           
       /* server.log(F("Last Values: "));
        server.log(F("U:"));
        server.log(u_last);
        server.log(F(" D:"));
        server.log(d_last);
        server.log(F(" L:"));
        server.log(l_last);
        server.log(F(" R:"));
        server.log(r_last);
    
        server.log(F("Ratios: "));
        server.log(F("UD Fi: "));
        server.log(ud_ratio_first);
        server.log(F(" UD La: "));
        server.log(ud_ratio_last);
        server.log(F(" LR Fi: "));
        server.log(lr_ratio_first);
        server.log(F(" LR La: "));
        server.log(lr_ratio_last);*/
           
        /* Determine the difference between the first and last ratios */
        ud_delta = ud_ratio_last - ud_ratio_first;
        lr_delta = lr_ratio_last - lr_ratio_first;
        
      /*  server.log("Deltas: ");
        server.log("UD: ");
        server.log(ud_delta);
        server.log(" LR: ");
        server.log(lr_delta);*/
    
        /* Accumulate the UD and LR delta values */
        gesture_ud_delta_ += ud_delta;
        gesture_lr_delta_ += lr_delta;
        
        /*server.log("Accumulations: ");
        server.log("UD: ");
        server.log(gesture_ud_delta_);
        server.log(" LR: ");
        server.log(gesture_lr_delta_);*/

        /* Determine U/D gesture */
        if( gesture_ud_delta_ >= GESTURE_SENSITIVITY_1 ) {
            gesture_ud_count_ = 1;
        } else if( gesture_ud_delta_ <= -GESTURE_SENSITIVITY_1 ) {
            gesture_ud_count_ = -1;
        } else {
            gesture_ud_count_ = 0;
        }
        
        /* Determine L/R gesture */
        if( gesture_lr_delta_ >= GESTURE_SENSITIVITY_1 ) {
            gesture_lr_count_ = 1;
        } else if( gesture_lr_delta_ <= -GESTURE_SENSITIVITY_1 ) {
            gesture_lr_count_ = -1;
        } else {
            gesture_lr_count_ = 0;
        }
        
        /* Determine Near/Far gesture */
        if( (gesture_ud_count_ == 0) && (gesture_lr_count_ == 0) ) {
            if( (math.abs(ud_delta) < GESTURE_SENSITIVITY_2) &&
                (math.abs(lr_delta) < GESTURE_SENSITIVITY_2) ) {
                
                if( (ud_delta == 0) && (lr_delta == 0) ) {
                    gesture_near_count_++;
                } else if( (ud_delta != 0) || (lr_delta != 0) ) {
                    gesture_far_count_++;
                }
                
                if( (gesture_near_count_ >= 10) && (gesture_far_count_ >= 2) ) {
                    if( (ud_delta == 0) && (lr_delta == 0) ) {
                        gesture_state_ = NEAR_STATE;
                    } else if( (ud_delta != 0) && (lr_delta != 0) ) {
                        gesture_state_ = FAR_STATE;
                    }
                    return true;
                }
            }
        } else {
            if( (math.abs(ud_delta) < GESTURE_SENSITIVITY_2) &&
                (math.abs(lr_delta) < GESTURE_SENSITIVITY_2) ) {
                    
                if( (ud_delta == 0) && (lr_delta == 0) ) {
                    gesture_near_count_++;
                }
                
                if( gesture_near_count_ >= 10 ) {
                    gesture_ud_count_ = 0;
                    gesture_lr_count_ = 0;
                    gesture_ud_delta_ = 0;
                    gesture_lr_delta_ = 0;
                }
            }
        }
        
        /*server.log("UD_CT: ");
        server.log(gesture_ud_count_);
        server.log(" LR_CT: ");
        server.log(gesture_lr_count_);
        server.log(" NEAR_CT: ");
        server.log(gesture_near_count_);
        server.log(" FAR_CT: ");
        server.log(gesture_far_count_);
        server.log("----------");*/
        
        return false;
    }
    
    /**
     * @brief Determines swipe direction or near/far state
     *
     * @return True if near/far event. False otherwise.
     */
    function decodeGesture()
    {
        /* Return if near or far event is detected */
        if( gesture_state_ == NEAR_STATE ) {
            gesture_motion_ = DIR_NEAR;
            return true;
        } else if ( gesture_state_ == FAR_STATE ) {
            gesture_motion_ = DIR_FAR;
            return true;
        }
        
        /* Determine swipe direction */
        if( (gesture_ud_count_ == -1) && (gesture_lr_count_ == 0) ) {
            gesture_motion_ = DIR_UP;
        } else if( (gesture_ud_count_ == 1) && (gesture_lr_count_ == 0) ) {
            gesture_motion_ = DIR_DOWN;
        } else if( (gesture_ud_count_ == 0) && (gesture_lr_count_ == 1) ) {
            gesture_motion_ = DIR_RIGHT;
        } else if( (gesture_ud_count_ == 0) && (gesture_lr_count_ == -1) ) {
            gesture_motion_ = DIR_LEFT;
        } else if( (gesture_ud_count_ == -1) && (gesture_lr_count_ == 1) ) {
            if( math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) ) {
                gesture_motion_ = DIR_UP;
            } else {
                gesture_motion_ = DIR_RIGHT;
            }
        } else if( (gesture_ud_count_ == 1) && (gesture_lr_count_ == -1) ) {
            if( math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) ) {
                gesture_motion_ = DIR_DOWN;
            } else {
                gesture_motion_ = DIR_LEFT;
            }
        } else if( (gesture_ud_count_ == -1) && (gesture_lr_count_ == -1) ) {
            if( math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) ) {
                gesture_motion_ = DIR_UP;
            } else {
                gesture_motion_ = DIR_LEFT;
            }
        } else if( (gesture_ud_count_ == 1) && (gesture_lr_count_ == 1) ) {
            if( math.abs(gesture_ud_delta_) > math.abs(gesture_lr_delta_) ) {
                gesture_motion_ = DIR_DOWN;
            } else {
                gesture_motion_ = DIR_RIGHT;
            }
        } else {
            return false;
        }
        
        return true;
    }
    
    /**************************************************************************
     * Getters and setters for register values
     **************************************************************************/
    
    /**
     * @brief Returns the lower threshold for proximity detection
     *
     * @return lower threshold
     */
    function getProxIntLowThresh()
    {
        local val;
        
        /* Read value from PILT register */
        if( null == (val = readi2cbyte(APDS9960_PILT)) ) {
            val = 0;
        }
        
        return val;
    }
    
    /**
     * @brief Sets the lower threshold for proximity detection
     *
     * @param[in] threshold the lower proximity threshold
     * @return True if operation successful. False otherwise.
     */
    function setProxIntLowThresh(threshold)
    {
        if( !writei2c(APDS9960_PILT, threshold) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Returns the high threshold for proximity detection
     *
     * @return high threshold
     */
    function getProxIntHighThresh()
    {
        local val;
        
        /* Read value from PIHT register */
        if( null == (val = readi2cbyte(APDS9960_PIHT)) ) {
            val = 0;
        }
        
        return val;
    }
    
    /**
     * @brief Sets the high threshold for proximity detection
     *
     * @param[in] threshold the high proximity threshold
     * @return True if operation successful. False otherwise.
     */
    function setProxIntHighThresh(threshold)
    {
        if( !writei2c(APDS9960_PIHT, threshold) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Returns LED drive strength for proximity and ALS
     *
     * Value    LED Current
     *   0        100 mA
     *   1         50 mA
     *   2         25 mA
     *   3         12.5 mA
     *
     * @return the value of the LED drive strength. 0xFF on failure.
     */
    function getLEDDrive()
    {
        local val;
        
        /* Read value from CONTROL register */
        if( null == (val = readi2cbyte(APDS9960_CONTROL)) ) {
            return ERROR;
        }
        
        /* Shift and mask out LED drive bits */
        val = (val >> 6) & 0x03;
        
        return val;
    }
    
    /**
     * @brief Sets the LED drive strength for proximity and ALS
     *
     * Value    LED Current
     *   0        100 mA
     *   1         50 mA
     *   2         25 mA
     *   3         12.5 mA
     *
     * @param[in] drive the value (0-3) for the LED drive strength
     * @return True if operation successful. False otherwise.
     */
    function setLEDDrive(drive)
    {
        local val;
        
        /* Read value from CONTROL register */
        if( null == (val = readi2cbyte(APDS9960_CONTROL)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        drive = drive & 0x03;
        drive = drive << 6;
        val = val & 0x3F;
        val = val | drive;
        
        /* Write register value back into CONTROL register */
        if( !writei2c(APDS9960_CONTROL, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Returns receiver gain for proximity detection
     *
     * Value    Gain
     *   0       1x
     *   1       2x
     *   2       4x
     *   3       8x
     *
     * @return the value of the proximity gain. 0xFF on failure.
     */
    function getProximityGain()
    {
        local val;
        
        /* Read value from CONTROL register */
        if( null == (val = readi2cbyte(APDS9960_CONTROL)) ) {
            return ERROR;
        }
        
        /* Shift and mask out PDRIVE bits */
        val = (val >> 2) & 0x03;
        
        return val;
    }
    
    /**
     * @brief Sets the receiver gain for proximity detection
     *
     * Value    Gain
     *   0       1x
     *   1       2x
     *   2       4x
     *   3       8x
     *
     * @param[in] drive the value (0-3) for the gain
     * @return True if operation successful. False otherwise.
     */
    function setProximityGain(drive)
    {
        local val;
        
        /* Read value from CONTROL register */
        if( null == (val = readi2cbyte(APDS9960_CONTROL)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        drive = drive & 0x03;
        drive = drive << 2;
        val = val & 0xF3;
        val = val | drive;
        
        /* Write register value back into CONTROL register */
        if( !writei2c(APDS9960_CONTROL, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Returns receiver gain for the ambient light sensor (ALS)
     *
     * Value    Gain
     *   0        1x
     *   1        4x
     *   2       16x
     *   3       64x
     *
     * @return the value of the ALS gain. 0xFF on failure.
     */
    function getAmbientLightGain()
    {
        local val;
        
        /* Read value from CONTROL register */
        if( null == (val = readi2cbyte(APDS9960_CONTROL)) ) {
            return ERROR;
        }
        
        /* Shift and mask out ADRIVE bits */
        val = val & 0x03;
        
        return val;
    }
    
    /**
     * @brief Sets the receiver gain for the ambient light sensor (ALS)
     *
     * Value    Gain
     *   0        1x
     *   1        4x
     *   2       16x
     *   3       64x
     *
     * @param[in] drive the value (0-3) for the gain
     * @return True if operation successful. False otherwise.
     */
    function setAmbientLightGain(drive)
    {
        local val;
        
        /* Read value from CONTROL register */
        if( null == (val = readi2cbyte(APDS9960_CONTROL)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        drive = drive & 0x03;
        val = val & 0xFC;
        val = val | drive;
        
        /* Write register value back into CONTROL register */
        if( !writei2c(APDS9960_CONTROL, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Get the current LED boost value
     * 
     * Value  Boost Current
     *   0        100%
     *   1        150%
     *   2        200%
     *   3        300%
     *
     * @return The LED boost value. 0xFF on failure.
     */
    function getLEDBoost()
    {
        local val;
        
        /* Read value from CONFIG2 register */
        if( null == (val = readi2cbyte(APDS9960_CONFIG2)) ) {
            return ERROR;
        }
        
        /* Shift and mask out LED_BOOST bits */
        val = (val >> 4) & 0x03;
        
        return val;
    }
    
    /**
     * @brief Sets the LED current boost value
     *
     * Value  Boost Current
     *   0        100%
     *   1        150%
     *   2        200%
     *   3        300%
     *
     * @param[in] drive the value (0-3) for current boost (100-300%)
     * @return True if operation successful. False otherwise.
     */
    function setLEDBoost(boost)
    {
        local val;
        
        /* Read value from CONFIG2 register */
        if( null == (val = readi2cbyte(APDS9960_CONFIG2)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        boost = boost & 0x03;
        boost = boost << 4;
        val = val & 0xCF;
        val = val | boost;
        
        /* Write register value back into CONFIG2 register */
        if( !writei2c(APDS9960_CONFIG2, val) ) {
            return false;
        }
        
        return true;
    }    
    
    /**
     * @brief Gets the entry proximity threshold for gesture sensing
     *
     * @return Current entry proximity threshold.
     */
    function getGestureEnterThresh()
    {
        local val;
        
        /* Read value from GPENTH register */
        if( null == (val = readi2cbyte(APDS9960_GPENTH)) ) {
            val = 0;
        }
        
        return val;
    }
    
    /**
     * @brief Sets the entry proximity threshold for gesture sensing
     *
     * @param[in] threshold proximity value needed to start gesture mode
     * @return True if operation successful. False otherwise.
     */
    function setGestureEnterThresh(threshold)
    {
        if( !writei2c(APDS9960_GPENTH, threshold) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets the exit proximity threshold for gesture sensing
     *
     * @return Current exit proximity threshold.
     */
    function getGestureExitThresh()
    {
        local val;
        
        /* Read value from GEXTH register */
        if( null == (val = readi2cbyte(APDS9960_GEXTH)) ) {
            val = 0;
        }
        
        return val;
    }
    
    /**
     * @brief Sets the exit proximity threshold for gesture sensing
     *
     * @param[in] threshold proximity value needed to end gesture mode
     * @return True if operation successful. False otherwise.
     */
    function setGestureExitThresh(threshold)
    {
        if( !writei2c(APDS9960_GEXTH, threshold) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets the gain of the photodiode during gesture mode
     *
     * Value    Gain
     *   0       1x
     *   1       2x
     *   2       4x
     *   3       8x
     *
     * @return the current photodiode gain. 0xFF on error.
     */
    function getGestureGain()
    {
        local val;
        
        /* Read value from GCONF2 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF2)) ) {
            return ERROR;
        }
        
        /* Shift and mask out GGAIN bits */
        val = (val >> 5) & 0x03;
        
        return val;
    }
    
    /**
     * @brief Sets the gain of the photodiode during gesture mode
     *
     * Value    Gain
     *   0       1x
     *   1       2x
     *   2       4x
     *   3       8x
     *
     * @param[in] gain the value for the photodiode gain
     * @return True if operation successful. False otherwise.
     */
    function setGestureGain(gain)
    {
        local val;
        
        /* Read value from GCONF2 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF2)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        gain = gain & 0x03;
        gain = gain << 5;
        val = val & 0x9F;
        val = val | gain;
        
        /* Write register value back into GCONF2 register */
        if( !writei2c(APDS9960_GCONF2, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets the drive current of the LED during gesture mode
     *
     * Value    LED Current
     *   0        100 mA
     *   1         50 mA
     *   2         25 mA
     *   3         12.5 mA
     *
     * @return the LED drive current value. 0xFF on error.
     */
    function getGestureLEDDrive()
    {
        local val;
        
        /* Read value from GCONF2 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF2)) ) {
            return ERROR;
        }
        
        /* Shift and mask out GLDRIVE bits */
        val = (val >> 3) & 0x03;
        
        return val;
    }
    
    /**
     * @brief Sets the LED drive current during gesture mode
     *
     * Value    LED Current
     *   0        100 mA
     *   1         50 mA
     *   2         25 mA
     *   3         12.5 mA
     *
     * @param[in] drive the value for the LED drive current
     * @return True if operation successful. False otherwise.
     */
    function setGestureLEDDrive(drive)
    {
        local val;
        
        /* Read value from GCONF2 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF2)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        drive = drive & 0x03;
        drive = drive << 3;
        val = val & 0xE7;
        val = val | drive;
        
        /* Write register value back into GCONF2 register */
        if( !writei2c(APDS9960_GCONF2, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets the time in low power mode between gesture detections
     *
     * Value    Wait time
     *   0          0 ms
     *   1          2.8 ms
     *   2          5.6 ms
     *   3          8.4 ms
     *   4         14.0 ms
     *   5         22.4 ms
     *   6         30.8 ms
     *   7         39.2 ms
     *
     * @return the current wait time between gestures. 0xFF on error.
     */
    function getGestureWaitTime()
    {
        local val;
        
        /* Read value from GCONF2 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF2)) ) {
            return ERROR;
        }
        
        /* Mask out GWTIME bits */
        val = val & 0x07;
        
        return val;
    }
    
    /**
     * @brief Sets the time in low power mode between gesture detections
     *
     * Value    Wait time
     *   0          0 ms
     *   1          2.8 ms
     *   2          5.6 ms
     *   3          8.4 ms
     *   4         14.0 ms
     *   5         22.4 ms
     *   6         30.8 ms
     *   7         39.2 ms
     *
     * @param[in] the value for the wait time
     * @return True if operation successful. False otherwise.
     */
    function setGestureWaitTime(time)
    {
        local val;
        
        /* Read value from GCONF2 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF2)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        time = time & 0x07;
        val = val & 0xF8;
        val = val | time;
        
        /* Write register value back into GCONF2 register */
        if( !writei2c(APDS9960_GCONF2, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets the low threshold for ambient light interrupts
     *
     * @return threshold current low threshold stored on the APDS-9960 if
     * operation successful. False otherwise.
     */
    function getLightIntLowThreshold()
    {
        local val_byte;
        threshold = 0;
        
        /* Read value from ambient light low threshold, low byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_AILTL)) ) {
            return false;
        }
        threshold = val_byte;
        
        /* Read value from ambient light low threshold, high byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_AILTH)) ) {
            return false;
        }
        threshold = threshold + (val_byte << 8);
        
        return threshold;
    }
    
    /**
     * @brief Sets the low threshold for ambient light interrupts
     *
     * @param[in] threshold low threshold value for interrupt to trigger
     * @return True if operation successful. False otherwise.
     */
    function setLightIntLowThreshold(threshold)
    {
        local val_low;
        local val_high;
        
        /* Break 16-bit threshold into 2 8-bit values */
        val_low = threshold & 0x00FF;
        val_high = (threshold & 0xFF00) >> 8;
        
        /* Write low byte */
        if( !writei2c(APDS9960_AILTL, val_low) ) {
            return false;
        }
        
        /* Write high byte */
        if( !writei2c(APDS9960_AILTH, val_high) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets the high threshold for ambient light interrupts
     *
     * @return threshold current low threshold stored on the APDS-9960 if
     * operation successful. False otherwise.
     */
    function getLightIntHighThreshold()
    {
        local val_byte;
        threshold = 0;
        
        /* Read value from ambient light high threshold, low byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_AIHTL)) ) {
            return false;
        }
        threshold = val_byte;
        
        /* Read value from ambient light high threshold, high byte register */
        if( null == (val_byte = readi2cbyte(APDS9960_AIHTH)) ) {
            return false;
        }
        threshold = threshold + (val_byte << 8);
        
        return threshold;
    }
    
    /**
     * @brief Sets the high threshold for ambient light interrupts
     *
     * @param[in] threshold high threshold value for interrupt to trigger
     * @return True if operation successful. False otherwise.
     */
    function setLightIntHighThreshold(threshold)
    {
        local val_low;
        local val_high;
        
        /* Break 16-bit threshold into 2 8-bit values */
        val_low = threshold & 0x00FF;
        val_high = (threshold & 0xFF00) >> 8;
        
        /* Write low byte */
        if( !writei2c(APDS9960_AIHTL, val_low) ) {
            return false;
        }
        
        /* Write high byte */
        if( !writei2c(APDS9960_AIHTH, val_high) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets the low threshold for proximity interrupts
     *
     * @return threshold current low threshold stored on the APDS-9960 if
     * operation successful. False otherwise.
     */
    // TODO: correct reference argument
    function getProximityIntLowThreshold(threshold)
    {
        threshold = 0;
        
        /* Read value from proximity low threshold register */
        if( null == (threshold = readi2cbyte(APDS9960_PILT)) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Sets the low threshold for proximity interrupts
     *
     * @param[in] threshold low threshold value for interrupt to trigger
     * @return True if operation successful. False otherwise.
     */
    function setProximityIntLowThreshold(threshold)
    {
        
        /* Write threshold value to register */
        if( !writei2c(APDS9960_PILT, threshold) ) {
            return false;
        }
        
        return true;
    }
        
    /**
     * @brief Gets the high threshold for proximity interrupts
     *
     * @param[out] threshold current low threshold stored on the APDS-9960
     * @return True if operation successful. False otherwise.
     */
    function getProximityIntHighThreshold()
    {
        threshold = 0;
        
        /* Read value from proximity low threshold register */
        if( null == (threshold = readi2cbyte(APDS9960_PIHT)) ) {
            return false;
        }
        
        return threshold;
    }
    
    /**
     * @brief Sets the high threshold for proximity interrupts
     *
     * @param[in] threshold high threshold value for interrupt to trigger
     * @return True if operation successful. False otherwise.
     */
    function setProximityIntHighThreshold(threshold)
    {
        
        /* Write threshold value to register */
        if( !writei2c(APDS9960_PIHT, threshold) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets if ambient light interrupts are enabled or not
     *
     * @return 1 if interrupts are enabled, 0 if not. 0xFF on error.
     */
    function getAmbientLightIntEnable()
    {
        local val;
        
        /* Read value from ENABLE register */
        if( null == (val = readi2cbyte(APDS9960_ENABLE)) ) {
            return ERROR;
        }
        
        /* Shift and mask out AIEN bit */
        val = (val >> 4) & 0x01;
        
        return val;
    }
    
    /**
     * @brief Turns ambient light interrupts on or off
     *
     * @param[in] enable 1 to enable interrupts, 0 to turn them off
     * @return True if operation successful. False otherwise.
     */
    function setAmbientLightIntEnable(enable)
    {
        local val;
        
        /* Read value from ENABLE register */
        if( null == (val = readi2cbyte(APDS9960_ENABLE)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        enable = enable & 0x01;
        enable = enable << 4;
        val = val & 0xEF;
        val = val | enable;
        
        /* Write register value back into ENABLE register */
        if( !writei2c(APDS9960_ENABLE, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets if proximity interrupts are enabled or not
     *
     * @return 1 if interrupts are enabled, 0 if not. 0xFF on error.
     */
    function getProximityIntEnable()
    {
        local val;
        
        /* Read value from ENABLE register */
        if( null == (val = readi2c(APDS9960_ENABLE)) ) {
            return ERROR;
        }
        
        /* Shift and mask out PIEN bit */
        val = (val >> 5) & 0x01;
        
        return val;
    }
    
    /**
     * @brief Turns proximity interrupts on or off
     *
     * @param[in] enable 1 to enable interrupts, 0 to turn them off
     * @return True if operation successful. False otherwise.
     */
    function setProximityIntEnable(enable)
    {
        local val;
        
        /* Read value from ENABLE register */
        if( null == (val = readi2cbyte(APDS9960_ENABLE)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        enable = enable & 0x01;
        enable = enable << 5;
        val = val & 0xDF;
        val = val | enable;
        
        /* Write register value back into ENABLE register */
        if( !writei2c(APDS9960_ENABLE, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Gets if gesture interrupts are enabled or not
     *
     * @return 1 if interrupts are enabled, 0 if not. 0xFF on error.
     */
    function getGestureIntEnable()
    {
        local val;
        
        /* Read value from GCONF4 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF4)) ) {
            return ERROR;
        }
        
        /* Shift and mask out GIEN bit */
        val = (val >> 1) & 0x01;
        
        return val;
    }
    
    /**
     * @brief Turns gesture-related interrupts on or off
     *
     * @param[in] enable 1 to enable interrupts, 0 to turn them off
     * @return True if operation successful. False otherwise.
     */
    function setGestureIntEnable(enable)
    {
        local val;
        
        /* Read value from GCONF4 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF4)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        enable = enable & 0x01;
        enable = enable << 1;
        val = val & 0xFD;
        val = val | enable;
        
        /* Write register value back into GCONF4 register */
        if( !writei2c(APDS9960_GCONF4, val) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Clears the ambient light interrupt
     *
     * @return True if operation completed successfully. False otherwise.
     */
    function clearAmbientLightInt()
    {
        local throwaway;
        if( null == (throwaway = readi2cbyte(APDS9960_AICLEAR)) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Clears the proximity interrupt
     *
     * @return True if operation completed successfully. False otherwise.
     */
    function clearProximityInt()
    {
        local throwaway;
        if( null == (throwaway = readi2cbyte(APDS9960_PICLEAR)) ) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Tells if the gesture state machine is currently running
     *
     * @return 1 if gesture state machine is running, 0 if not. 0xFF on error.
     */
    function getGestureMode()
    {
        local val;
        
        /* Read value from GCONF4 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF4)) ) {
            return ERROR;
        }
        
        /* Mask out GMODE bit */
        val = val & 0x01;
        
        return val;
    }
    
    /**
     * @brief Tells the state machine to either enter or exit gesture state machine
     *
     * @param[in] mode 1 to enter gesture state machine, 0 to exit.
     * @return True if operation successful. False otherwise.
     */
    function setGestureMode(mode)
    {
        local val;
        
        /* Read value from GCONF4 register */
        if( null == (val = readi2cbyte(APDS9960_GCONF4)) ) {
            return false;
        }
        
        /* Set bits in register to given value */
        mode = mode & 0x01;
        val = val & 0xFE;
        val = val | mode;
        
        /* Write register value back into GCONF4 register */
        if( !writei2c(APDS9960_GCONF4, val) ) {
            return false;
        }
        
        return true;
    }

}